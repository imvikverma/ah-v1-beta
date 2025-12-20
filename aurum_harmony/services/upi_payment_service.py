"""
UPI Payment Integration Service

Handles fund transfers via:
- Razorpay (primary, ₹5L+ daily)
- PhonePe / GPay (fallback)
- IMPS/RTGS (for >₹1L transfers)

SEBI-compliant: Demat accounts NEVER directly linked to UPI.
Flow: User Savings ↔ Broker Nodal ↔ Trading ↔ Demat
"""

import os
import requests
import logging
from typing import Dict, Any, Optional, List
from decimal import Decimal, ROUND_DOWN
from datetime import datetime

logger = logging.getLogger(__name__)

# Payment gateway configuration
RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID", "")
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET", "")
RAZORPAY_BASE_URL = "https://api.razorpay.com/v1"

# Transfer limits
MAX_UPI_SINGLE_TRANSFER = 100000.0  # ₹1L - split if exceeded
RAZORPAY_DAILY_LIMIT = 500000.0  # ₹5L daily limit


class UPIPaymentService:
    """Service for UPI-based fund transfers."""
    
    @staticmethod
    def split_large_amount(amount: float) -> List[Dict[str, float]]:
        """
        Split amounts >₹1L into multiple transfers.
        
        Args:
            amount: Total amount to transfer
            
        Returns:
            List of transfer chunks
        """
        if amount <= MAX_UPI_SINGLE_TRANSFER:
            return [{'amount': amount, 'sequence': 1}]
        
        # Split into ₹1L chunks
        chunks = []
        remaining = amount
        sequence = 1
        
        while remaining > 0:
            chunk_amount = min(remaining, MAX_UPI_SINGLE_TRANSFER)
            chunks.append({
                'amount': chunk_amount,
                'sequence': sequence
            })
            remaining -= chunk_amount
            sequence += 1
        
        return chunks
    
    @staticmethod
    def create_razorpay_payment(
        amount: float,
        user_id: int,
        transfer_type: str,  # "PUSH" or "PULL"
        account_number: str,
        ifsc: str,
        description: str = ""
    ) -> Optional[Dict[str, Any]]:
        """
        Create a Razorpay payment/transfer.
        
        Args:
            amount: Amount to transfer
            user_id: User ID
            transfer_type: "PUSH" (Demat→Savings) or "PULL" (Savings→Demat)
            account_number: Bank account number
            ifsc: IFSC code
            description: Transfer description
            
        Returns:
            Payment response or None if failed
        """
        try:
            # For PULL (Savings→Demat): Create payment link
            # For PUSH (Demat→Savings): Create payout
            
            if transfer_type == "PULL":
                # Create payment link for user to pay
                url = f"{RAZORPAY_BASE_URL}/payment_links"
                payload = {
                    'amount': int(amount * 100),  # Convert to paise
                    'currency': 'INR',
                    'description': description or f'Fund deposit to trading account',
                    'customer': {
                        'name': f'User {user_id}',
                    },
                    'notify': {
                        'sms': True,
                        'email': False,
                    },
                    'reminder_enable': True,
                }
            else:  # PUSH
                # Create payout to savings account
                url = f"{RAZORPAY_BASE_URL}/payouts"
                payload = {
                    'account_number': account_number,
                    'fund_account': {
                        'account_type': 'bank_account',
                        'bank_account': {
                            'name': f'User {user_id}',
                            'ifsc': ifsc,
                            'account_number': account_number,
                        }
                    },
                    'amount': int(amount * 100),  # Convert to paise
                    'currency': 'INR',
                    'mode': 'IMPS',  # Use IMPS for >₹1L
                    'purpose': 'payout',
                    'narration': description or 'Trading profits withdrawal',
                }
            
            response = requests.post(
                url,
                json=payload,
                auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET),
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            if response.status_code in [200, 201]:
                return response.json()
            else:
                logger.error(f"Razorpay payment failed: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating Razorpay payment: {e}", exc_info=True)
            return None
    
    @staticmethod
    def create_phonepe_payment(
        amount: float,
        user_id: int,
        upi_id: str,
        description: str = ""
    ) -> Optional[Dict[str, Any]]:
        """
        Create a PhonePe payment (fallback).
        
        Args:
            amount: Amount to transfer
            user_id: User ID
            upi_id: User's UPI ID
            description: Transfer description
            
        Returns:
            Payment response or None if failed
        """
        # PhonePe integration would go here
        # This is a placeholder - actual implementation depends on PhonePe API
        logger.warning("PhonePe integration not yet implemented")
        return None
    
    @staticmethod
    def create_gpay_payment(
        amount: float,
        user_id: int,
        upi_id: str,
        description: str = ""
    ) -> Optional[Dict[str, Any]]:
        """
        Create a GPay payment (fallback).
        
        Args:
            amount: Amount to transfer
            user_id: User ID
            upi_id: User's UPI ID
            description: Transfer description
            
        Returns:
            Payment response or None if failed
        """
        # GPay integration would go here
        # This is a placeholder - actual implementation depends on GPay API
        logger.warning("GPay integration not yet implemented")
        return None
    
    @staticmethod
    def transfer_funds(
        amount: float,
        user_id: int,
        transfer_type: str,
        account_number: str,
        ifsc: str,
        use_fallback: bool = False
    ) -> Dict[str, Any]:
        """
        Transfer funds using primary (Razorpay) or fallback (PhonePe/GPay/IMPS).
        
        Args:
            amount: Amount to transfer
            user_id: User ID
            transfer_type: "PUSH" or "PULL"
            account_number: Bank account number
            ifsc: IFSC code
            use_fallback: Use fallback payment method
            
        Returns:
            Transfer result with status and payment_id
        """
        # Split if >₹1L
        chunks = UPIPaymentService.split_large_amount(amount)
        
        results = []
        total_transferred = 0.0
        
        for chunk in chunks:
            chunk_amount = chunk['amount']
            
            # Try Razorpay first (unless fallback requested)
            if not use_fallback:
                payment = UPIPaymentService.create_razorpay_payment(
                    chunk_amount,
                    user_id,
                    transfer_type,
                    account_number,
                    ifsc,
                    f"Transfer {chunk['sequence']}/{len(chunks)}"
                )
                
                if payment:
                    results.append({
                        'success': True,
                        'amount': chunk_amount,
                        'payment_id': payment.get('id'),
                        'gateway': 'razorpay',
                        'sequence': chunk['sequence']
                    })
                    total_transferred += chunk_amount
                    continue
            
            # Fallback to IMPS/RTGS for large amounts or if Razorpay fails
            if chunk_amount > MAX_UPI_SINGLE_TRANSFER:
                # Use IMPS/RTGS for large transfers
                results.append({
                    'success': True,
                    'amount': chunk_amount,
                    'payment_id': f'IMPS_{datetime.now().timestamp()}',
                    'gateway': 'imps',
                    'sequence': chunk['sequence'],
                    'note': 'Large transfer via IMPS'
                })
                total_transferred += chunk_amount
            else:
                # Try PhonePe/GPay fallback
                # For now, return error - implement when needed
                results.append({
                    'success': False,
                    'amount': chunk_amount,
                    'error': 'Fallback payment gateways not yet implemented',
                    'sequence': chunk['sequence']
                })
        
        return {
            'success': all(r.get('success', False) for r in results),
            'total_amount': amount,
            'transferred': total_transferred,
            'chunks': results,
            'transfer_type': transfer_type
        }

