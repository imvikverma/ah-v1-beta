"""
Low Premium Option Picker
Selects low-premium options for intraday trading to minimize losses

Strategy:
- Focus on low premium options (cheap strikes)
- Prefer OTM/ATM options for lower cost
- Filter by liquidity and volume
- Select strikes within premium range
"""

import logging
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)


class OptionType(str, Enum):
    """Option type."""
    CALL = "CE"
    PUT = "PE"


@dataclass
class OptionContract:
    """Represents an option contract."""
    symbol: str  # e.g., "NIFTY50"
    strike: float
    option_type: OptionType
    expiry: str  # e.g., "2026-01-05"
    premium: float
    lot_size: int
    volume: int = 0
    open_interest: int = 0
    bid: float = 0.0
    ask: float = 0.0
    ltp: float = 0.0
    underlying_price: float = 0.0
    iv: float = 0.0  # Implied volatility
    
    @property
    def contract_name(self) -> str:
        """Get contract name for broker."""
        return f"{self.symbol}{self.strike}{self.option_type.value}"
    
    @property
    def is_atm(self) -> bool:
        """Check if strike is at-the-money."""
        if self.underlying_price == 0:
            return False
        diff_pct = abs(self.strike - self.underlying_price) / self.underlying_price * 100
        return diff_pct < 0.5  # Within 0.5%
    
    @property
    def is_otm(self) -> bool:
        """Check if strike is out-of-the-money."""
        if self.underlying_price == 0:
            return False
        if self.option_type == OptionType.CALL:
            return self.strike > self.underlying_price
        else:  # PUT
            return self.strike < self.underlying_price
    
    @property
    def moneyness_pct(self) -> float:
        """Get moneyness percentage."""
        if self.underlying_price == 0:
            return 0.0
        return ((self.strike - self.underlying_price) / self.underlying_price) * 100


class LowPremiumOptionPicker:
    """
    Selects low-premium options for intraday trading.
    
    Strategy:
    - Prefer low premium options (minimize cost, maximize leverage)
    - Focus on OTM/ATM strikes
    - Filter by liquidity
    - Select within premium range
    """
    
    def __init__(
        self,
        max_premium: float = 200.0,  # Maximum premium per lot
        min_premium: float = 10.0,   # Minimum premium (avoid too cheap, low liquidity)
        preferred_moneyness_range: Tuple[float, float] = (-2.0, 2.0),  # -2% to +2% from ATM
        min_volume: int = 1000,  # Minimum volume for liquidity
        prefer_otm: bool = True  # Prefer OTM over ITM
    ):
        """
        Initialize low premium option picker.
        
        Args:
            max_premium: Maximum premium per lot (default: ₹200)
            min_premium: Minimum premium per lot (default: ₹10)
            preferred_moneyness_range: Preferred moneyness range in % (default: -2% to +2%)
            min_volume: Minimum volume for liquidity check
            prefer_otm: Prefer out-of-the-money options
        """
        self.max_premium = max_premium
        self.min_premium = min_premium
        self.preferred_moneyness_range = preferred_moneyness_range
        self.min_volume = min_volume
        self.prefer_otm = prefer_otm
        logger.info(
            f"LowPremiumOptionPicker initialized: "
            f"Premium range ₹{min_premium}-{max_premium}, "
            f"Moneyness {preferred_moneyness_range[0]}% to {preferred_moneyness_range[1]}%"
        )
    
    def select_option(
        self,
        symbol: str,
        direction: str,  # "BUY" or "SELL"
        underlying_price: float,
        option_chain: List[Dict],
        expiry: Optional[str] = None
    ) -> Optional[OptionContract]:
        """
        Select best low-premium option for given direction.
        
        Args:
            symbol: Index symbol (NIFTY50, BANKNIFTY, SENSEX)
            direction: "BUY" or "SELL"
            underlying_price: Current underlying price
            option_chain: Option chain data from broker/NSE
            expiry: Expiry date (default: current expiry)
            
        Returns:
            Selected OptionContract or None
        """
        # Determine option type based on direction
        # BUY direction = BUY CALL (bullish - betting price goes up)
        # SELL direction = BUY PUT (bearish - betting price goes down)
        # We're buying options, so:
        # - BUY direction → BUY CALL (price up = profit)
        # - SELL direction → BUY PUT (price down = profit)
        if direction.upper() == "BUY":
            option_type = OptionType.CALL
        else:  # SELL (bearish)
            option_type = OptionType.PUT
        
        # Filter and score options
        candidates = []
        
        for option_data in option_chain:
            try:
                contract = self._parse_option_data(option_data, symbol, option_type, underlying_price, expiry)
                if not contract:
                    continue
                
                # Apply filters
                if not self._passes_filters(contract):
                    continue
                
                # Score option (lower score = better for low premium)
                score = self._score_option(contract, underlying_price)
                candidates.append((score, contract))
                
            except Exception as e:
                logger.debug(f"Error parsing option data: {e}")
                continue
        
        if not candidates:
            logger.warning(f"No suitable low-premium options found for {symbol} {direction}")
            return None
        
        # Sort by score (ascending) and return best
        candidates.sort(key=lambda x: x[0])
        best_option = candidates[0][1]
        
        logger.info(
            f"Selected option: {best_option.contract_name} @ ₹{best_option.premium:.2f} "
            f"(Strike: {best_option.strike}, Moneyness: {best_option.moneyness_pct:.2f}%)"
        )
        
        return best_option
    
    def _parse_option_data(
        self,
        option_data: Dict,
        symbol: str,
        option_type: OptionType,
        underlying_price: float,
        expiry: Optional[str]
    ) -> Optional[OptionContract]:
        """Parse option data into OptionContract."""
        try:
            # Extract strike
            strike = float(option_data.get("strikePrice") or option_data.get("strike") or 0)
            if strike == 0:
                return None
            
            # Check option type matches
            option_type_str = option_data.get("optionType") or option_data.get("option_type") or ""
            if option_type_str.upper() not in ["CE", "CALL", "PE", "PUT"]:
                # If not specified, we'll filter later
                pass
            elif option_type == OptionType.CALL and option_type_str.upper() not in ["CE", "CALL"]:
                return None  # Not a CALL option
            elif option_type == OptionType.PUT and option_type_str.upper() not in ["PE", "PUT"]:
                return None  # Not a PUT option
            
            # Extract premium (use LTP, lastPrice, or mid of bid/ask)
            ltp = float(option_data.get("lastPrice") or option_data.get("ltp") or option_data.get("last_price") or 0)
            bid = float(option_data.get("bidPrice") or option_data.get("bid") or 0)
            ask = float(option_data.get("askPrice") or option_data.get("ask") or 0)
            
            if ltp > 0:
                premium = ltp
            elif bid > 0 and ask > 0:
                premium = (bid + ask) / 2
            else:
                return None  # No price data
            
            # Extract other data
            volume = int(option_data.get("volume") or option_data.get("totalTradedVolume") or 0)
            oi = int(option_data.get("openInterest") or option_data.get("oi") or 0)
            iv = float(option_data.get("impliedVolatility") or option_data.get("iv") or 0)
            
            # Get lot size (default based on symbol)
            lot_size = self._get_lot_size(symbol)
            
            # Get expiry
            if not expiry:
                expiry = option_data.get("expiry") or datetime.now().strftime("%Y-%m-%d")
            
            contract = OptionContract(
                symbol=symbol,
                strike=strike,
                option_type=option_type,
                expiry=expiry,
                premium=premium,
                lot_size=lot_size,
                volume=volume,
                open_interest=oi,
                bid=bid,
                ask=ask,
                ltp=ltp,
                underlying_price=underlying_price,
                iv=iv
            )
            
            return contract
            
        except Exception as e:
            logger.debug(f"Error parsing option: {e}")
            return None
    
    def _passes_filters(self, contract: OptionContract) -> bool:
        """Check if option passes all filters."""
        # Premium range filter
        if contract.premium < self.min_premium or contract.premium > self.max_premium:
            return False
        
        # Volume filter (if available)
        if contract.volume > 0 and contract.volume < self.min_volume:
            return False
        
        # Moneyness filter
        moneyness = contract.moneyness_pct
        if moneyness < self.preferred_moneyness_range[0] or moneyness > self.preferred_moneyness_range[1]:
            # Allow slightly outside range but prefer within
            if abs(moneyness) > abs(self.preferred_moneyness_range[1]) * 1.5:
                return False
        
        return True
    
    def _score_option(self, contract: OptionContract, underlying_price: float) -> float:
        """
        Score option (lower = better for low premium strategy).
        
        Scoring factors:
        - Premium (lower = better)
        - Moneyness (prefer OTM/ATM)
        - Volume (higher = better for liquidity)
        - Distance from preferred range
        """
        score = 0.0
        
        # Premium score (lower premium = lower score)
        premium_score = contract.premium / self.max_premium * 100
        score += premium_score * 0.4  # 40% weight
        
        # Moneyness score
        moneyness = abs(contract.moneyness_pct)
        if contract.is_otm and self.prefer_otm:
            moneyness_score = moneyness * 0.5  # Prefer OTM
        elif contract.is_atm:
            moneyness_score = 0  # ATM is best
        else:
            moneyness_score = moneyness * 2  # Penalize ITM
        
        score += moneyness_score * 0.3  # 30% weight
        
        # Volume score (higher volume = lower score)
        if contract.volume > 0:
            volume_score = max(0, 100 - (contract.volume / 10000) * 10)  # Normalize
        else:
            volume_score = 50  # Unknown volume
        
        score += volume_score * 0.2  # 20% weight
        
        # Distance from preferred range
        moneyness = contract.moneyness_pct
        if moneyness < self.preferred_moneyness_range[0]:
            range_penalty = abs(moneyness - self.preferred_moneyness_range[0])
        elif moneyness > self.preferred_moneyness_range[1]:
            range_penalty = abs(moneyness - self.preferred_moneyness_range[1])
        else:
            range_penalty = 0
        
        score += range_penalty * 0.1  # 10% weight
        
        return score
    
    def _get_lot_size(self, symbol: str) -> int:
        """Get lot size for symbol."""
        lot_sizes = {
            "NIFTY50": 50,
            "BANKNIFTY": 15,
            "SENSEX": 10
        }
        return lot_sizes.get(symbol.upper(), 50)  # Default 50
    
    def select_multiple_options(
        self,
        symbol: str,
        direction: str,
        underlying_price: float,
        option_chain: List[Dict],
        count: int = 3,
        expiry: Optional[str] = None
    ) -> List[OptionContract]:
        """
        Select multiple low-premium options (for diversification).
        
        Args:
            symbol: Index symbol
            direction: "BUY" or "SELL"
            underlying_price: Current underlying price
            option_chain: Option chain data
            count: Number of options to select
            expiry: Expiry date
            
        Returns:
            List of selected OptionContract objects
        """
        selected = []
        remaining_chain = option_chain.copy()
        
        for i in range(count):
            option = self.select_option(symbol, direction, underlying_price, remaining_chain, expiry)
            if option:
                selected.append(option)
                # Remove selected strike from remaining chain to avoid duplicates
                remaining_chain = [
                    opt for opt in remaining_chain
                    if opt.get("strikePrice") != option.strike or
                       opt.get("strike") != option.strike
                ]
            else:
                break
        
        return selected
