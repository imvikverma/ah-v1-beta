"""
Regulatory Compliance Monitor for AurumHarmony

Monitors SEBI, NSE, and BSE circulars, regulations, and compliance requirements.
Automatically adjusts trading strategies based on regulatory changes.
"""

import logging
import requests
import json
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import re
from dataclasses import dataclass

try:
    from bs4 import BeautifulSoup
    BS4_AVAILABLE = True
except ImportError:
    BS4_AVAILABLE = False
    BeautifulSoup = None
    logging.warning("BeautifulSoup not available - regulatory scraping disabled")

logger = logging.getLogger(__name__)

@dataclass
class RegulatoryUpdate:
    """Represents a regulatory update."""
    source: str  # SEBI, NSE, BSE
    title: str
    content: str
    date: datetime
    category: str  # trading, settlement, risk, etc.
    impact: str  # high, medium, low
    url: str
    processed: bool = False

class RegulatoryMonitor:
    """
    Monitors regulatory updates from SEBI, NSE, and BSE.

    Automatically detects changes that could affect trading strategies
    and triggers appropriate system adjustments.
    """

    def __init__(self):
        self.updates: List[RegulatoryUpdate] = []
        self.last_check = datetime.now() - timedelta(hours=25)  # Force initial check

        # Regulatory sources
        self.sources = {
            'sebi': {
                'name': 'SEBI',
                'url': 'https://www.sebi.gov.in/sebiweb/home/HomeAction.do?doListing=yes&sid=1',
                'api_url': None,  # SEBI doesn't have public API
                'scraper_needed': True
            },
            'nse': {
                'name': 'NSE',
                'url': 'https://www.nseindia.com/resources/exchange-communication-circulars',
                'api_url': 'https://www.nseindia.com/api/circulars',
                'scraper_needed': False
            },
            'bse': {
                'name': 'BSE',
                'url': 'https://www.bseindia.com/circulars.html',
                'api_url': None,
                'scraper_needed': True
            }
        }

        # Impact keywords that require immediate attention
        self.critical_keywords = [
            'trading halt', 'circuit breaker', 'position limits', 'margin requirements',
            'settlement cycle', 'delivery requirements', 'short selling',
            'algorithmic trading', 'high frequency', 'market manipulation'
        ]

        # Category mapping
        self.category_keywords = {
            'trading': ['trading', 'order', 'execution', 'matching'],
            'settlement': ['settlement', 'delivery', 'pay-in', 'pay-out'],
            'risk': ['margin', 'risk', 'leverage', 'exposure'],
            'market': ['market', 'circuit', 'halt', 'suspension'],
            'compliance': ['compliance', 'reporting', 'disclosure']
        }

        logger.info("Regulatory Monitor initialized")

    def check_for_updates(self) -> List[RegulatoryUpdate]:
        """
        Check all regulatory sources for new updates.

        Returns:
            List of new regulatory updates found
        """
        logger.info("Checking for regulatory updates")

        new_updates = []

        for source_key, source_info in self.sources.items():
            try:
                updates = self._check_source(source_key, source_info)
                new_updates.extend(updates)
            except Exception as e:
                logger.error(f"Error checking {source_info['name']}: {e}")

        # Filter out already processed updates
        new_updates = [u for u in new_updates if not self._is_already_processed(u)]

        if new_updates:
            logger.warning(f"Found {len(new_updates)} new regulatory updates")
            self.updates.extend(new_updates)

        return new_updates

    def _check_source(self, source_key: str, source_info: Dict[str, Any]) -> List[RegulatoryUpdate]:
        """Check a specific regulatory source."""
        updates = []

        if source_info.get('scraper_needed'):
            updates = self._scrape_updates(source_key, source_info)
        else:
            updates = self._fetch_api_updates(source_key, source_info)

        return updates

    def _scrape_updates(self, source_key: str, source_info: Dict[str, Any]) -> List[RegulatoryUpdate]:
        """Scrape updates from regulatory website."""
        updates = []

        if not BS4_AVAILABLE:
            logger.info(f"Skipping {source_info['name']} scraping - BeautifulSoup not available")
            return updates

        try:
            headers = {
                'User-Agent': 'AurumHarmony Regulatory Monitor/1.0',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
                'Accept-Encoding': 'gzip, deflate',
                'Connection': 'keep-alive',
            }

            response = requests.get(source_info['url'], headers=headers, timeout=30)
            response.raise_for_status()

            if BS4_AVAILABLE:
                soup = BeautifulSoup(response.content, 'html.parser')
            else:
                logger.warning("BeautifulSoup not available for parsing")
                return updates

            # Extract updates based on source
            if source_key == 'sebi':
                updates = self._parse_sebi_updates(soup)
            elif source_key == 'bse':
                updates = self._parse_bse_updates(soup)

        except Exception as e:
            logger.error(f"Error scraping {source_info['name']}: {e}")

        return updates

    def _fetch_api_updates(self, source_key: str, source_info: Dict[str, Any]) -> List[RegulatoryUpdate]:
        """Fetch updates from regulatory API."""
        updates = []

        try:
            headers = {
                'User-Agent': 'AurumHarmony Regulatory Monitor/1.0',
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }

            response = requests.get(source_info['api_url'], headers=headers, timeout=30)
            response.raise_for_status()

            data = response.json()
            updates = self._parse_api_response(source_key, data)

        except Exception as e:
            logger.error(f"Error fetching {source_info['name']} API: {e}")

        return updates

    def _parse_sebi_updates(self, soup: BeautifulSoup) -> List[RegulatoryUpdate]:
        """Parse SEBI website updates."""
        updates = []

        # Look for circular listings (adjust selectors based on actual page structure)
        circulars = soup.find_all('div', class_=re.compile(r'circular|notice|update'))

        for circular in circulars[:10]:  # Check last 10 updates
            try:
                title_elem = circular.find('h3') or circular.find('a')
                date_elem = circular.find('span', class_=re.compile(r'date|time'))

                if title_elem and date_elem:
                    title = title_elem.get_text().strip()
                    date_str = date_elem.get_text().strip()

                    # Parse date (adjust format as needed)
                    try:
                        date = datetime.strptime(date_str, '%d-%m-%Y')
                    except:
                        date = datetime.now()

                    # Determine category and impact
                    category = self._determine_category(title)
                    impact = self._determine_impact(title)

                    update = RegulatoryUpdate(
                        source='SEBI',
                        title=title,
                        content='',  # Would need to fetch full content
                        date=date,
                        category=category,
                        impact=impact,
                        url='https://www.sebi.gov.in'  # Base URL
                    )

                    updates.append(update)

            except Exception as e:
                logger.error(f"Error parsing SEBI update: {e}")

        return updates

    def _parse_bse_updates(self, soup: BeautifulSoup) -> List[RegulatoryUpdate]:
        """Parse BSE website updates."""
        updates = []
        # Similar parsing logic for BSE
        return updates

    def _parse_api_response(self, source_key: str, data: Dict[str, Any]) -> List[RegulatoryUpdate]:
        """Parse API response for updates."""
        updates = []

        # Parse based on API structure (example for NSE)
        if source_key == 'nse' and 'data' in data:
            for item in data['data'][:10]:  # Check last 10
                try:
                    update = RegulatoryUpdate(
                        source='NSE',
                        title=item.get('title', ''),
                        content=item.get('description', ''),
                        date=datetime.fromisoformat(item.get('date', datetime.now().isoformat())),
                        category=self._determine_category(item.get('title', '')),
                        impact=self._determine_impact(item.get('title', '')),
                        url=item.get('url', '')
                    )
                    updates.append(update)
                except Exception as e:
                    logger.error(f"Error parsing NSE API update: {e}")

        return updates

    def _determine_category(self, title: str) -> str:
        """Determine the category of a regulatory update."""
        title_lower = title.lower()

        for category, keywords in self.category_keywords.items():
            if any(keyword in title_lower for keyword in keywords):
                return category

        return 'general'

    def _determine_impact(self, title: str) -> str:
        """Determine the impact level of a regulatory update."""
        title_lower = title.lower()

        if any(keyword in title_lower for keyword in self.critical_keywords):
            return 'high'

        if any(word in title_lower for word in ['change', 'amendment', 'revision', 'update']):
            return 'medium'

        return 'low'

    def _is_already_processed(self, update: RegulatoryUpdate) -> bool:
        """Check if an update has already been processed."""
        for existing in self.updates:
            if (existing.source == update.source and
                existing.title == update.title and
                existing.date.date() == update.date.date()):
                return True
        return False

    def get_critical_updates(self) -> List[RegulatoryUpdate]:
        """Get all critical regulatory updates."""
        return [u for u in self.updates if u.impact == 'high' and not u.processed]

    def mark_update_processed(self, update: RegulatoryUpdate):
        """Mark an update as processed."""
        update.processed = True
        logger.info(f"Marked regulatory update as processed: {update.title}")

    def get_updates_by_category(self, category: str) -> List[RegulatoryUpdate]:
        """Get updates by category."""
        return [u for u in self.updates if u.category == category]

    def get_recent_updates(self, days: int = 7) -> List[RegulatoryUpdate]:
        """Get updates from the last N days."""
        cutoff = datetime.now() - timedelta(days=days)
        return [u for u in self.updates if u.date >= cutoff]
