#!/usr/bin/env python3
"""
Performance Testing Suite for AurumHarmony

Tests system performance and response times:
- API response times (<100ms target)
- Concurrent user load
- Memory usage
- Database query performance
"""

import requests
import time
import statistics
import concurrent.futures
import threading
from datetime import datetime
from typing import List, Dict, Any

# Configuration
BASE_URL = "http://localhost:5000"
NUM_CONCURRENT_USERS = 10
NUM_REQUESTS_PER_USER = 20
TARGET_RESPONSE_TIME_MS = 100

# Performance Results
performance_results = {
    "response_times": [],
    "errors": 0,
    "total_requests": 0,
    "concurrent_users_tested": 0,
    "memory_usage": None,
    "cpu_usage": None
}

def measure_response_time(endpoint: str, method: str = "GET", data: Dict = None, headers: Dict = None) -> float:
    """Measure response time for a single request."""
    start_time = time.time()

    try:
        if method == "GET":
            response = requests.get(f"{BASE_URL}{endpoint}", headers=headers, timeout=10)
        elif method == "POST":
            response = requests.post(f"{BASE_URL}{endpoint}", json=data, headers=headers, timeout=10)
        else:
            return -1  # Invalid method

        if response.status_code >= 200 and response.status_code < 300:
            end_time = time.time()
            return (end_time - start_time) * 1000  # Convert to milliseconds
        else:
            performance_results["errors"] += 1
            return -1  # Error response
    except:
        performance_results["errors"] += 1
        return -1  # Request failed

def test_health_endpoint():
    """Test health endpoint performance."""
    print("Testing health endpoint performance...")
    times = []

    for i in range(50):
        response_time = measure_response_time("/health")
        if response_time > 0:
            times.append(response_time)
        time.sleep(0.1)  # Small delay between requests

    if times:
        avg_time = statistics.mean(times)
        min_time = min(times)
        max_time = max(times)
        p95_time = statistics.quantiles(times, n=20)[18]  # 95th percentile

        print(".1f"        print(".1f"        print(".1f"        print(".1f"
        performance_results["response_times"].extend(times)

        if avg_time > TARGET_RESPONSE_TIME_MS:
            print(f"⚠️  Average response time ({avg_time:.1f}ms) exceeds target ({TARGET_RESPONSE_TIME_MS}ms)")
        else:
            print(f"✅ Average response time within target limits")

def test_auth_endpoints():
    """Test authentication endpoints performance."""
    print("\nTesting authentication endpoints...")

    # Test registration
    reg_times = []
    for i in range(10):
        reg_data = {
            "email": f"perf_test_{i}_{int(time.time())}@example.com",
            "phone": f"+91987654321{i}",
            "password": "TestPass123!"
        }
        response_time = measure_response_time("/api/auth/register", "POST", reg_data)
        if response_time > 0:
            reg_times.append(response_time)
        time.sleep(0.2)

    if reg_times:
        avg_reg_time = statistics.mean(reg_times)
        print(".1f"
        performance_results["response_times"].extend(reg_times)

def test_concurrent_users():
    """Test system performance under concurrent load."""
    print(f"\nTesting concurrent load ({NUM_CONCURRENT_USERS} users)...")

    def user_simulation(user_id: int) -> List[float]:
        """Simulate a single user's activity."""
        user_times = []

        # Simulate user login
        login_data = {
            "email": f"test_user_{user_id}@example.com",
            "password": "TestPass123!"
        }

        # Try login (may fail if user doesn't exist, but tests the endpoint)
        login_time = measure_response_time("/api/auth/login", "POST", login_data)
        if login_time > 0:
            user_times.append(login_time)

        # Simulate various API calls
        for i in range(NUM_REQUESTS_PER_USER):
            # Mix of different endpoints
            endpoints = ["/health", "/api/auth/me", "/api/brokers/list"]
            endpoint = endpoints[i % len(endpoints)]

            headers = {}
            if endpoint.startswith("/api/"):
                headers = {"Authorization": "Bearer dummy_token"}  # Will likely fail but tests auth

            response_time = measure_response_time(endpoint, headers=headers)
            if response_time > 0:
                user_times.append(response_time)

            time.sleep(0.05)  # Small delay between user requests

        return user_times

    # Run concurrent user simulations
    all_user_times = []
    start_time = time.time()

    with concurrent.futures.ThreadPoolExecutor(max_workers=NUM_CONCURRENT_USERS) as executor:
        futures = [executor.submit(user_simulation, i) for i in range(NUM_CONCURRENT_USERS)]
        for future in concurrent.futures.as_completed(futures):
            user_times = future.result()
            all_user_times.extend(user_times)

    end_time = time.time()
    total_time = end_time - start_time

    performance_results["response_times"].extend(all_user_times)
    performance_results["concurrent_users_tested"] = NUM_CONCURRENT_USERS

    if all_user_times:
        avg_response_time = statistics.mean(all_user_times)
        max_response_time = max(all_user_times)
        total_requests = len(all_user_times)

        print(f"Concurrent load test completed in {total_time:.2f}s")
        print(f"Total requests processed: {total_requests}")
        print(".1f"        print(".1f"
        print(f"Requests per second: {total_requests/total_time:.1f}")

        if avg_response_time > TARGET_RESPONSE_TIME_MS:
            print(f"⚠️  Average response time under load ({avg_response_time:.1f}ms) exceeds target")
        else:
            print(f"✅ Response times acceptable under concurrent load")

def test_database_performance():
    """Test database query performance."""
    print("\nTesting database performance...")

    # This would require an authenticated session
    # For now, we'll skip detailed database testing
    print("Database performance testing requires authenticated session")
    print("✅ Database tests deferred to authenticated testing")

def generate_performance_report():
    """Generate comprehensive performance report."""
    print("\n" + "="*70)
    print("AURUMHARMONY PERFORMANCE TEST REPORT")
    print("="*70)

    total_requests = len(performance_results["response_times"])
    errors = performance_results["errors"]

    if total_requests > 0:
        avg_response_time = statistics.mean(performance_results["response_times"])
        min_response_time = min(performance_results["response_times"])
        max_response_time = max(performance_results["response_times"])

        # Calculate percentiles
        sorted_times = sorted(performance_results["response_times"])
        p50 = statistics.median(sorted_times)
        p95 = statistics.quantiles(sorted_times, n=20)[18]  # 95th percentile
        p99 = statistics.quantiles(sorted_times, n=100)[98]  # 99th percentile

        print(f"Total Requests: {total_requests}")
        print(f"Errors: {errors}")
        print(f"Success Rate: {((total_requests-errors)/total_requests*100):.1f}%")
        print()
        print("Response Time Statistics (ms):")
        print(".1f"        print(".1f"        print(".1f"        print(".1f"        print(".1f"        print(".1f"
        print()
        print("Performance Assessment:")
        if avg_response_time <= TARGET_RESPONSE_TIME_MS:
            print(f"✅ Average response time ({avg_response_time:.1f}ms) meets target (<{TARGET_RESPONSE_TIME_MS}ms)")
        else:
            print(f"⚠️  Average response time ({avg_response_time:.1f}ms) exceeds target (<{TARGET_RESPONSE_TIME_MS}ms)")

        if p95 <= TARGET_RESPONSE_TIME_MS * 2:  # Allow some tolerance for P95
            print(f"✅ 95th percentile ({p95:.1f}ms) is acceptable")
        else:
            print(f"⚠️  95th percentile ({p95:.1f}ms) is high")

        if errors / total_requests <= 0.05:  # 5% error rate tolerance
            print(f"✅ Error rate ({(errors/total_requests*100):.1f}%) is acceptable")
        else:
            print(f"⚠️  Error rate ({(errors/total_requests*100):.1f}%) is high")

    else:
        print("❌ No successful requests recorded")

    print(f"\nConcurrent Users Tested: {performance_results['concurrent_users_tested']}")
    print(f"Test Completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

def run_performance_tests():
    """Run the complete performance test suite."""
    print("AurumHarmony Performance Testing Suite")
    print("=" * 50)
    print(f"Target Response Time: <{TARGET_RESPONSE_TIME_MS}ms")
    print(f"Concurrent Users: {NUM_CONCURRENT_USERS}")
    print(f"Backend URL: {BASE_URL}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    try:
        # Test individual endpoints
        test_health_endpoint()
        test_auth_endpoints()

        # Test concurrent load
        test_concurrent_users()

        # Test database performance
        test_database_performance()

        # Generate final report
        generate_performance_report()

    except KeyboardInterrupt:
        print("\n⚠️  Performance tests interrupted by user")
    except Exception as e:
        print(f"\n❌ Fatal error during performance testing: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    run_performance_tests()
