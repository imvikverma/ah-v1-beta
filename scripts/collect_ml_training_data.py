"""
ML Training Data Collector
Collects and formats test results for RandomForest + LSTM model training

This script:
1. Collects all test results from today
2. Extracts features for ML models
3. Formats data for RandomForest (tabular) and LSTM (time series)
4. Saves training datasets
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import pandas as pd
import numpy as np
from pathlib import Path

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class MLTrainingDataCollector:
    """
    Collects and formats test data for ML model training.
    """
    
    def __init__(self):
        self.logs_dir = os.path.join(project_root, '_local', 'logs')
        self.reports_dir = os.path.join(project_root, '_local', 'reports')
        self.ml_data_dir = os.path.join(project_root, '_local', 'ml_training_data')
        os.makedirs(self.ml_data_dir, exist_ok=True)
        
        logger.info("MLTrainingDataCollector initialized")
    
    def collect_all_test_results(self) -> List[Dict[str, Any]]:
        """Collect all test results from today."""
        today = datetime.now().date()
        all_results = []
        
        # Find all result files from today
        result_files = list(Path(self.logs_dir).glob("*test*.json"))
        result_files.extend(list(Path(self.logs_dir).glob("*aggregate*.json")))
        
        for result_file in result_files:
            try:
                # Check if file is from today
                file_time = datetime.fromtimestamp(result_file.stat().st_mtime)
                if file_time.date() == today:
                    with open(result_file, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        all_results.append({
                            "file": result_file.name,
                            "timestamp": file_time.isoformat(),
                            "data": data
                        })
            except Exception as e:
                logger.warning(f"Failed to read {result_file}: {e}")
        
        logger.info(f"Collected {len(all_results)} test result files")
        return all_results
    
    def extract_trade_features(self, trade: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extract features from a single trade for ML training.
        
        Features for RandomForest:
        - Symbol
        - Side (BUY/SELL)
        - Quantity
        - Price
        - Order type
        - Timestamp features (hour, minute, day_of_week)
        - Market conditions (if available)
        
        Features for LSTM:
        - Price sequence
        - Volume sequence
        - Time-based features
        """
        timestamp = datetime.fromisoformat(trade.get("timestamp", datetime.now().isoformat()))
        
        features = {
            # Trade characteristics
            "symbol": trade.get("symbol", "UNKNOWN"),
            "side": 1 if trade.get("side", "BUY") == "BUY" else 0,  # Binary encoding
            "quantity": float(trade.get("quantity", 0)),
            "price": float(trade.get("price", 0)),
            "value": float(trade.get("value", 0)),
            "pnl": float(trade.get("pnl", 0)),
            
            # Time features
            "hour": timestamp.hour,
            "minute": timestamp.minute,
            "day_of_week": timestamp.weekday(),  # 0=Monday, 6=Sunday
            "is_market_open": 1 if 9 <= timestamp.hour < 15 else 0,
            
            # Derived features
            "is_profitable": 1 if trade.get("pnl", 0) > 0 else 0,
            "pnl_percent": (trade.get("pnl", 0) / trade.get("value", 1)) * 100 if trade.get("value", 0) > 0 else 0,
        }
        
        return features
    
    def extract_cycle_features(self, cycle_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extract features from a trading cycle.
        
        Features:
        - Available exposure
        - Orders placed/filled/rejected
        - Positions opened/closed
        - PnL
        - Exposure utilization
        """
        return {
            "available_exposure": float(cycle_data.get("available_exposure", 0)),
            "max_exposure": float(cycle_data.get("max_exposure", 0)),
            "exposure_utilization": float(cycle_data.get("exposure_utilization", 0)),
            "orders_placed": int(cycle_data.get("orders_placed", 0)),
            "orders_filled": int(cycle_data.get("orders_filled", 0)),
            "orders_rejected": int(cycle_data.get("orders_rejected", 0)),
            "positions_opened": int(cycle_data.get("positions_opened", 0)),
            "positions_closed": int(cycle_data.get("positions_closed", 0)),
            "pnl": float(cycle_data.get("pnl", 0)),
        }
    
    def create_randomforest_dataset(self, all_results: List[Dict[str, Any]]) -> pd.DataFrame:
        """
        Create tabular dataset for RandomForest model.
        
        Each row represents a trade with features and target (PnL).
        """
        rows = []
        
        for result_data in all_results:
            data = result_data.get("data", {})
            
            # Extract trades from top level
            trades = data.get("trades", [])
            if isinstance(trades, list) and len(trades) > 0:
                for trade in trades:
                    if isinstance(trade, dict):
                        features = self.extract_trade_features(trade)
                        rows.append(features)
            
            # Extract from run results (if aggregate)
            run_results = data.get("run_results", [])
            if isinstance(run_results, list):
                for run in run_results:
                    full_results = run.get("full_results", {})
                    if isinstance(full_results, dict):
                        trades = full_results.get("trades", [])
                        if isinstance(trades, list) and len(trades) > 0:
                            for trade in trades:
                                if isinstance(trade, dict):
                                    features = self.extract_trade_features(trade)
                                    rows.append(features)
            
            # Also check latest_report for trade data
            latest_report = data.get("latest_report", {})
            if isinstance(latest_report, dict):
                # Some reports might have trade lists
                report_trades = latest_report.get("trades", [])
                if isinstance(report_trades, list) and len(report_trades) > 0:
                    for trade in report_trades:
                        if isinstance(trade, dict):
                            features = self.extract_trade_features(trade)
                            rows.append(features)
        
        if not rows:
            logger.warning("No trade data found for RandomForest dataset")
            return pd.DataFrame()
        
        df = pd.DataFrame(rows)
        logger.info(f"Created RandomForest dataset: {len(df)} rows, {len(df.columns)} features")
        return df
    
    def create_lstm_dataset(self, all_results: List[Dict[str, Any]], sequence_length: int = 20) -> Dict[str, np.ndarray]:
        """
        Create time series dataset for LSTM model.
        
        Returns sequences of prices, volumes, and features for time series prediction.
        """
        sequences = []
        targets = []
        
        for result_data in all_results:
            data = result_data.get("data", {})
            
            # Collect trades in chronological order
            trades = []
            
            # Extract trades from various sources
            if "trades" in data:
                trades.extend(data["trades"])
            
            if "run_results" in data:
                for run in data["run_results"]:
                    full_results = run.get("full_results", {})
                    if "trades" in full_results:
                        trades.extend(full_results["trades"])
            
            # Sort by timestamp
            trades.sort(key=lambda x: x.get("timestamp", ""))
            
            # Create sequences
            for i in range(len(trades) - sequence_length):
                sequence = trades[i:i + sequence_length]
                target_trade = trades[i + sequence_length]
                
                # Extract sequence features
                seq_features = []
                for trade in sequence:
                    features = self.extract_trade_features(trade)
                    seq_features.append([
                        features["price"],
                        features["quantity"],
                        features["value"],
                        features["pnl"],
                        features["hour"],
                        features["minute"],
                        features["side"],
                    ])
                
                # Target: next trade PnL
                target = float(target_trade.get("pnl", 0))
                
                sequences.append(seq_features)
                targets.append(target)
        
        if not sequences:
            logger.warning("No sequence data found for LSTM dataset")
            return {
                "X": np.array([]),
                "y": np.array([])
            }
        
        X = np.array(sequences)
        y = np.array(targets)
        
        logger.info(f"Created LSTM dataset: {len(sequences)} sequences, shape {X.shape}")
        return {
            "X": X,
            "y": y
        }
    
    def create_cycle_dataset(self, all_results: List[Dict[str, Any]]) -> pd.DataFrame:
        """
        Create dataset from trading cycles for cycle-level predictions.
        """
        rows = []
        
        for result_data in all_results:
            data = result_data.get("data", {})
            
            # Extract cycle data if available
            # This would come from cycle-level logging in test results
            # For now, we'll extract from aggregate statistics
            
            aggregate_stats = data.get("aggregate_statistics", {})
            if aggregate_stats:
                avgs = aggregate_stats.get("averages", {})
                if avgs:
                    row = {
                        "total_trades": avgs.get("total_trades", {}).get("mean", 0),
                        "win_rate": avgs.get("win_rate_percent", {}).get("mean", 0),
                        "total_pnl": avgs.get("total_pnl", {}).get("mean", 0),
                        "total_volume": avgs.get("total_volume", {}).get("mean", 0),
                    }
                    rows.append(row)
        
        if not rows:
            logger.warning("No cycle data found")
            return pd.DataFrame()
        
        df = pd.DataFrame(rows)
        logger.info(f"Created cycle dataset: {len(df)} rows")
        return df
    
    def save_datasets(self, rf_df: pd.DataFrame, lstm_data: Dict, cycle_df: pd.DataFrame):
        """Save all datasets to files."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save RandomForest dataset
        if not rf_df.empty:
            rf_file = os.path.join(self.ml_data_dir, f"randomforest_dataset_{timestamp}.csv")
            rf_df.to_csv(rf_file, index=False)
            logger.info(f"Saved RandomForest dataset: {rf_file} ({len(rf_df)} rows)")
        
        # Save LSTM dataset
        if lstm_data["X"].size > 0:
            lstm_file = os.path.join(self.ml_data_dir, f"lstm_dataset_{timestamp}.npz")
            np.savez(
                lstm_file,
                X=lstm_data["X"],
                y=lstm_data["y"]
            )
            logger.info(f"Saved LSTM dataset: {lstm_file} (shape: {lstm_data['X'].shape})")
        
        # Save cycle dataset
        if not cycle_df.empty:
            cycle_file = os.path.join(self.ml_data_dir, f"cycle_dataset_{timestamp}.csv")
            cycle_df.to_csv(cycle_file, index=False)
            logger.info(f"Saved cycle dataset: {cycle_file} ({len(cycle_df)} rows)")
        
        # Save metadata
        metadata = {
            "timestamp": datetime.now().isoformat(),
            "randomforest_rows": len(rf_df) if not rf_df.empty else 0,
            "lstm_sequences": len(lstm_data["X"]) if lstm_data["X"].size > 0 else 0,
            "cycle_rows": len(cycle_df) if not cycle_df.empty else 0,
            "features": {
                "randomforest": list(rf_df.columns) if not rf_df.empty else [],
                "lstm_sequence_length": lstm_data["X"].shape[1] if lstm_data["X"].size > 0 else 0,
                "lstm_features": lstm_data["X"].shape[2] if lstm_data["X"].size > 0 else 0,
            }
        }
        
        metadata_file = os.path.join(self.ml_data_dir, f"dataset_metadata_{timestamp}.json")
        with open(metadata_file, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2)
        
        logger.info(f"Saved metadata: {metadata_file}")
    
    def collect_and_format(self):
        """Main method to collect and format all training data."""
        logger.info("=" * 80)
        logger.info("COLLECTING ML TRAINING DATA")
        logger.info("=" * 80)
        
        # Collect all test results
        all_results = self.collect_all_test_results()
        
        if not all_results:
            logger.warning("No test results found. Run tests first.")
            return
        
        # Create datasets
        logger.info("\nCreating RandomForest dataset...")
        rf_df = self.create_randomforest_dataset(all_results)
        
        logger.info("\nCreating LSTM dataset...")
        lstm_data = self.create_lstm_dataset(all_results)
        
        logger.info("\nCreating cycle dataset...")
        cycle_df = self.create_cycle_dataset(all_results)
        
        # Save datasets
        logger.info("\nSaving datasets...")
        self.save_datasets(rf_df, lstm_data, cycle_df)
        
        logger.info("\n" + "=" * 80)
        logger.info("ML TRAINING DATA COLLECTION COMPLETE")
        logger.info("=" * 80)
        
        return {
            "randomforest": rf_df,
            "lstm": lstm_data,
            "cycle": cycle_df
        }


if __name__ == "__main__":
    collector = MLTrainingDataCollector()
    datasets = collector.collect_and_format()
    
    if datasets:
        print("\n[OK] Datasets created successfully!")
        print(f"  - RandomForest: {len(datasets['randomforest'])} rows")
        if datasets['lstm']['X'].size > 0:
            print(f"  - LSTM: {len(datasets['lstm']['X'])} sequences")
        else:
            print(f"  - LSTM: No sequences yet (waiting for more test data)")
        print(f"  - Cycle: {len(datasets['cycle'])} rows")
