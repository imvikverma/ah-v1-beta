"""
Broker Adapter Factory

Creates appropriate broker adapters based on configuration and available brokers.
Supports live data paper trading when Kotak Neo is available.
Supports live trading when HDFC Sky is available.
"""

from __future__ import annotations

import logging
import os
from typing import Optional
from dotenv import load_dotenv

from aurum_harmony.engines.trade_execution.trade_execution import (
    BrokerAdapter,
    PaperBrokerAdapter,
)
from aurum_harmony.engines.trade_execution.live_data_paper_adapter import (
    LiveDataPaperAdapter,
)
from aurum_harmony.engines.trade_execution.hdfc_sky_paper_adapter import (
    HDFCSkyPaperAdapter,
)

load_dotenv()

logger = logging.getLogger(__name__)


def create_broker_adapter(
    use_live_data: bool = True,
    initial_balance: float = 100000.0,
    kotak_client: Optional[object] = None,
    hdfc_client: Optional[object] = None,
    use_hdfc_for_live: bool = False,
    use_hdfc_for_paper: bool = False,
) -> BrokerAdapter:
    """
    Create appropriate broker adapter based on configuration.
    
    Args:
        use_live_data: If True and Kotak Neo is available, use live data paper adapter
        initial_balance: Starting balance for paper trading
        kotak_client: Optional authenticated KotakNeoAPI instance
        hdfc_client: Optional authenticated HDFCSkyAPI instance
        use_hdfc_for_live: If True and HDFC Sky is available, use HDFC Sky for live trading
        use_hdfc_for_paper: If True and HDFC Sky is available, use HDFC Sky for paper trading with live data
        
    Returns:
        BrokerAdapter instance (HDFCSkyBrokerAdapter, HDFCSkyPaperAdapter, LiveDataPaperAdapter, or PaperBrokerAdapter)
    """
    # If live trading is requested and HDFC Sky client is available
    if use_hdfc_for_live and hdfc_client:
        try:
            from aurum_harmony.engines.trade_execution.hdfc_sky_adapter import HDFCSkyBrokerAdapter
            
            # Check if client is authenticated
            if hasattr(hdfc_client, 'is_authenticated') and hdfc_client.is_authenticated():
                logger.info("Creating HDFCSkyBrokerAdapter for live trading")
                return HDFCSkyBrokerAdapter(hdfc_client)
            else:
                logger.warning("HDFC Sky client provided but not authenticated, using standard paper adapter")
        except Exception as e:
            logger.warning(f"Error creating HDFCSkyBrokerAdapter: {e}, falling back to standard paper adapter")
    
    # If paper trading with HDFC Sky live data is requested
    if use_hdfc_for_paper and hdfc_client:
        try:
            # Check if client is authenticated
            if hasattr(hdfc_client, 'is_authenticated') and hdfc_client.is_authenticated():
                logger.info("Creating HDFCSkyPaperAdapter for paper trading with live data")
                return HDFCSkyPaperAdapter(
                    hdfc_client=hdfc_client,
                    initial_balance=initial_balance
                )
            else:
                logger.warning("HDFC Sky client provided but not authenticated, using standard paper adapter")
        except Exception as e:
            logger.warning(f"Error creating HDFCSkyPaperAdapter: {e}, falling back to standard paper adapter")
    
    # If live data is requested and Kotak client is available
    if use_live_data and kotak_client:
        try:
            # Check if client is authenticated
            if hasattr(kotak_client, 'is_authenticated') and kotak_client.is_authenticated():
                logger.info("Creating LiveDataPaperAdapter with Kotak Neo live data")
                return LiveDataPaperAdapter(
                    kotak_client=kotak_client,
                    initial_balance=initial_balance
                )
            else:
                logger.warning("Kotak client provided but not authenticated, using standard paper adapter")
        except Exception as e:
            logger.warning(f"Error creating LiveDataPaperAdapter: {e}, falling back to standard paper adapter")
    
    # Default to standard paper adapter
    logger.info("Creating standard PaperBrokerAdapter")
    return PaperBrokerAdapter(initial_balance=initial_balance)


def get_kotak_client_from_env() -> Optional[object]:
    """
    Create and authenticate Kotak Neo client from environment variables.
    
    Returns:
        Authenticated KotakNeoAPI instance or None if not available
    """
    try:
        from api.kotak_neo import KotakNeoAPI
        
        access_token = os.getenv("KOTAK_NEO_ACCESS_TOKEN")
        mobile_number = os.getenv("KOTAK_NEO_MOBILE_NUMBER")
        client_code = os.getenv("KOTAK_NEO_CLIENT_CODE")
        
        if not all([access_token, mobile_number, client_code]):
            logger.debug("Kotak Neo credentials not found in environment")
            return None
        
        # Remove 'Bearer ' prefix if present
        if access_token.startswith("Bearer "):
            access_token = access_token[7:]
        
        # Create client (but don't authenticate yet - that requires TOTP/MPIN)
        client = KotakNeoAPI(
            access_token=access_token,
            mobile_number=mobile_number,
            client_code=client_code
        )
        
        # Check if we have stored tokens (from previous session)
        # TODO: Load from database/file if available
        
        return client
        
    except Exception as e:
        logger.warning(f"Error creating Kotak Neo client: {e}")
        return None


def get_hdfc_client_from_env() -> Optional[object]:
    """
    Create and authenticate HDFC Sky client from environment variables.
    
    Returns:
        Authenticated HDFCSkyAPI instance or None if not available
    """
    try:
        from api.hdfc_sky_api import HDFCSkyAPI
        
        api_key = os.getenv("HDFC_SKY_API_KEY")
        api_secret = os.getenv("HDFC_SKY_API_SECRET")
        token_id = os.getenv("HDFC_SKY_TOKEN_ID")
        access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")
        
        if not api_key or not api_secret:
            logger.debug("HDFC Sky API key or secret not found in environment")
            return None
        
        # Create client
        client = HDFCSkyAPI(
            api_key=api_key,
            api_secret=api_secret,
            token_id=token_id,
            access_token=access_token
        )
        
        # Check if authenticated
        if not client.is_authenticated():
            logger.debug("HDFC Sky client created but not authenticated. Set HDFC_SKY_TOKEN_ID or HDFC_SKY_ACCESS_TOKEN")
            return None
        
        logger.info("HDFC Sky client created and authenticated from environment")
        return client
        
    except Exception as e:
        logger.warning(f"Error creating HDFC Sky client: {e}")
        return None


__all__ = ["create_broker_adapter", "get_kotak_client_from_env", "get_hdfc_client_from_env"]

