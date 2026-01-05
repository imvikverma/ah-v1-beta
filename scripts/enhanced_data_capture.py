"""
Enhanced Data Capture
Captures every possible data point from test runs for comprehensive ML training

Captures:
- Every trade detail
- Every price movement
- Every order state change
- Every position update
- Every cycle metric
- Market conditions
- System state
"""

import os
import sys
import json
import logging
from datetime import datetime
from typing import Dict, Any, List
from pathlib import Path

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class EnhancedDataCapture:
    """
    Enhanced data capture for maximum data points.
    """
    
    def __init__(self):
        self.capture_dir = os.path.join(project_root, '_local', 'enhanced_data_capture')
        os.makedirs(self.capture_dir, exist_ok=True)
        logger.info("EnhancedDataCapture initialized")
    
    def capture_all_test_data(self):
        """Capture all available test data comprehensively."""
        logger.info("=" * 80)
        logger.info("ENHANCED DATA CAPTURE - CAPTURING ALL DATA POINTS")
        logger.info("=" * 80)
        
        # Find all test result files
        logs_dir = os.path.join(project_root, '_local', 'logs')
        comprehensive_dir = os.path.join(project_root, '_local', 'comprehensive_test_data')
        
        all_data = {
            "capture_timestamp": datetime.now().isoformat(),
            "test_results": [],
            "comprehensive_data": [],
            "ml_datasets": [],
            "statistics": {}
        }
        
        # Collect test results
        result_files = list(Path(logs_dir).glob("*test*.json"))
        result_files.extend(list(Path(logs_dir).glob("*aggregate*.json")))
        result_files.extend(list(Path(logs_dir).glob("*max_trades*.json")))
        
        for result_file in result_files:
            try:
                with open(result_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    all_data["test_results"].append({
                        "file": result_file.name,
                        "timestamp": datetime.fromtimestamp(result_file.stat().st_mtime).isoformat(),
                        "data": data
                    })
            except Exception as e:
                logger.warning(f"Failed to read {result_file}: {e}")
        
        # Collect comprehensive data
        if os.path.exists(comprehensive_dir):
            comp_files = list(Path(comprehensive_dir).glob("*.json"))
            for comp_file in comp_files:
                try:
                    with open(comp_file, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        all_data["comprehensive_data"].append({
                            "file": comp_file.name,
                            "timestamp": datetime.fromtimestamp(comp_file.stat().st_mtime).isoformat(),
                            "data": data
                        })
                except Exception as e:
                    logger.warning(f"Failed to read {comp_file}: {e}")
        
        # Calculate statistics
        total_trades = 0
        total_cycles = 0
        
        for result in all_data["test_results"]:
            data = result.get("data", {})
            trades = data.get("trades", [])
            if isinstance(trades, list):
                total_trades += len(trades)
            
            cycles = data.get("cycles", [])
            if isinstance(cycles, list):
                total_cycles += len(cycles)
            
            total_cycles += data.get("total_cycles", 0)
        
        for comp in all_data["comprehensive_data"]:
            data = comp.get("data", {})
            trades = data.get("all_trades", [])
            if isinstance(trades, list):
                total_trades += len(trades)
            
            cycles = data.get("all_cycles", [])
            if isinstance(cycles, list):
                total_cycles += len(cycles)
        
        all_data["statistics"] = {
            "total_test_results": len(all_data["test_results"]),
            "total_comprehensive_files": len(all_data["comprehensive_data"]),
            "total_trades": total_trades,
            "total_cycles": total_cycles,
            "average_trades_per_cycle": total_trades / total_cycles if total_cycles > 0 else 0
        }
        
        # Save comprehensive capture
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        capture_file = os.path.join(self.capture_dir, f"enhanced_capture_{timestamp}.json")
        
        with open(capture_file, 'w', encoding='utf-8') as f:
            json.dump(all_data, f, indent=2, default=str)
        
        logger.info(f"\n[OK] Enhanced data capture saved: {capture_file}")
        logger.info(f"  - Test Results: {all_data['statistics']['total_test_results']}")
        logger.info(f"  - Comprehensive Files: {all_data['statistics']['total_comprehensive_files']}")
        logger.info(f"  - Total Trades: {all_data['statistics']['total_trades']}")
        logger.info(f"  - Total Cycles: {all_data['statistics']['total_cycles']}")
        logger.info(f"  - File Size: {os.path.getsize(capture_file) / 1024 / 1024:.2f} MB")
        
        return all_data


if __name__ == "__main__":
    capture = EnhancedDataCapture()
    data = capture.capture_all_test_data()
    
    print(f"\n[OK] Enhanced capture complete!")
    print(f"  Total Trades Captured: {data['statistics']['total_trades']}")
    print(f"  Total Cycles Captured: {data['statistics']['total_cycles']}")
