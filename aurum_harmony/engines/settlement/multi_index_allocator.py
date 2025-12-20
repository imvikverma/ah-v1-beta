"""
Multi-Index Capital Allocator for AurumHarmony

Allocates capital equally across indices, brokers, and accounts.
Key: ₹40,000 PER INDEX (not split)

Example:
- 3 indices × ₹40,000 per index = ₹120,000 total capital
- Each index gets ₹40,000 (full amount, not divided)
"""

import logging
from typing import Dict, Any, List

logger = logging.getLogger(__name__)


class MultiIndexCapitalAllocator:
    """
    Allocates capital equally across indices, brokers, and accounts.
    
    Rules:
    - ₹40,000 PER INDEX (not split)
    - ₹40,000 PER BROKER (not split)
    - ₹40,000 PER ACCOUNT (not split)
    - Always square & equal allocation
    """
    
    INDICES = ["NIFTY50", "BANKNIFTY", "SENSEX"]
    
    @staticmethod
    def allocate_capital(
        per_index_capital: float,
        num_indices: int = 3,
        num_brokers: int = 1,
        num_accounts: int = 1
    ) -> Dict[str, Any]:
        """
        Allocate capital equally across all dimensions.
        
        Key: Each index gets ₹40,000 (not split)
        Total Capital = per_index_capital × num_indices
        
        Args:
            per_index_capital: Capital per index (e.g., ₹40,000)
            num_indices: Number of indices (default 3)
            num_brokers: Number of brokers (default 1)
            num_accounts: Number of accounts (default 1)
            
        Returns:
            Dictionary with allocation breakdown
        """
        # Total capital = per_index × num_indices (not split)
        total_capital = per_index_capital * num_indices
        
        # Per broker = per_index × num_indices (if multiple brokers, each gets full amount)
        per_broker_capital = per_index_capital * num_indices if num_brokers > 0 else total_capital
        
        # Per account = per_index × num_indices (if multiple accounts, each gets full amount)
        per_account_capital = per_index_capital * num_indices if num_accounts > 0 else total_capital
        
        # Create allocation matrix
        allocation_matrix = {}
        for i, index_name in enumerate(MultiIndexCapitalAllocator.INDICES[:num_indices]):
            allocation_matrix[index_name] = {
                "capital": per_index_capital,  # ₹40K per index (not split)
                "index_number": i + 1,
            }
        
        logger.info(
            f"Capital allocated: Per Index={per_index_capital}, "
            f"Total={total_capital}, Indices={num_indices}"
        )
        
        return {
            "total_capital": total_capital,
            "per_index_capital": per_index_capital,  # ₹40K per index (not split)
            "per_broker_capital": per_broker_capital,
            "per_account_capital": per_account_capital,
            "allocation_matrix": allocation_matrix,
            "num_indices": num_indices,
            "num_brokers": num_brokers,
            "num_accounts": num_accounts,
        }
    
    @staticmethod
    def get_index_allocation(
        total_capital: float,
        num_indices: int = 3
    ) -> float:
        """
        Get capital per index.
        
        Since each index gets ₹40K (not split), we calculate:
        per_index = total_capital / num_indices
        
        But the key is: total_capital = per_index × num_indices
        
        Args:
            total_capital: Total capital available
            num_indices: Number of indices
            
        Returns:
            Capital per index
        """
        return total_capital / num_indices

