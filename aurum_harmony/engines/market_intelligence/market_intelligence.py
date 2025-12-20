"""
Market Intelligence Engine for AurumHarmony

Monitors news, corporate announcements, economic events, and market-moving developments.
Provides real-time intelligence to adjust trading strategies and risk parameters.
"""

import logging
import requests
import json
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
import re
from urllib.parse import urlparse

try:
    import feedparser
    FEEDPARSER_AVAILABLE = True
except ImportError:
    FEEDPARSER_AVAILABLE = False
    logging.warning("feedparser not available - RSS feed parsing disabled")

try:
    import yfinance as yf
    YFINANCE_AVAILABLE = True
except ImportError:
    YFINANCE_AVAILABLE = False
    logging.warning("yfinance not available - fallback data disabled")

logger = logging.getLogger(__name__)

@dataclass
class MarketEvent:
    """Represents a market-moving event."""
    event_type: str  # news, economic, corporate, political
    title: str
    summary: str
    source: str
    url: str
    timestamp: datetime
    sentiment: str  # positive, negative, neutral
    impact: str  # high, medium, low
    symbols_affected: List[str]
    processed: bool = False

class MarketIntelligenceEngine:
    """
    Market Intelligence Engine that monitors various sources for market-moving information.

    Sources monitored:
    - Financial news feeds (Reuters, Bloomberg, CNBC)
    - Corporate announcements (NSE, BSE)
    - Economic indicators and events
    - Political and regulatory developments
    - Social media sentiment (optional)
    """

    def __init__(self):
        self.events: List[MarketEvent] = []
        self.last_check = datetime.now() - timedelta(hours=2)  # Force initial check

        # News sources configuration
        self.news_sources = {
            'reuters': {
                'name': 'Reuters',
                'rss_url': 'https://feeds.reuters.com/reuters/INbusinessNews',
                'api_key': None,
                'enabled': True
            },
            'bloomberg': {
                'name': 'Bloomberg',
                'rss_url': 'https://feeds.bloomberg.com/markets/news.rss',
                'api_key': None,
                'enabled': True
            },
            'moneycontrol': {
                'name': 'Moneycontrol',
                'rss_url': 'https://www.moneycontrol.com/rss/latestnews.xml',
                'api_key': None,
                'enabled': True
            },
            'economictimes': {
                'name': 'Economic Times',
                'rss_url': 'https://economictimes.indiatimes.com/rssfeedsdefault.cms',
                'api_key': None,
                'enabled': True
            }
        }

        # Corporate announcement sources
        self.corporate_sources = {
            'nse_announcements': {
                'name': 'NSE Corporate Announcements',
                'url': 'https://www.nseindia.com/api/corporate-announcements',
                'enabled': True
            },
            'bse_announcements': {
                'name': 'BSE Corporate Announcements',
                'url': 'https://www.bseindia.com/corporates/ann.aspx',
                'enabled': True
            }
        }

        # Economic indicators to monitor
        self.economic_indicators = [
            'GDP', 'CPI', 'PPI', 'Unemployment', 'Retail Sales',
            'Industrial Production', 'Trade Balance', 'FDI',
            'Inflation', 'Interest Rate', 'Forex Reserves'
        ]

        # Keywords that indicate market impact
        self.impact_keywords = {
            'high': [
                'merger', 'acquisition', 'bankruptcy', 'delisting', 'trading halt',
                'circuit breaker', 'market crash', 'recession', 'crisis',
                'government intervention', 'policy change', 'rate cut', 'rate hike'
            ],
            'medium': [
                'earnings', 'quarterly results', 'dividend', 'bonus', 'split',
                'expansion', 'investment', 'partnership', 'contract win',
                'regulatory approval', 'policy announcement'
            ],
            'low': [
                'conference', 'webinar', 'award', 'milestone', 'appointment'
            ]
        }

        # Company name to symbol mapping (simplified)
        self.company_symbols = {
            'reliance': ['RELIANCE', 'RELIANCENS'],
            'tcs': ['TCS', 'TCSNS'],
            'infosys': ['INFY', 'INFYNS'],
            'hdfc': ['HDFC', 'HDFCBANK'],
            'icici': ['ICICI', 'ICICIBANK'],
            'sbi': ['SBI', 'SBIN'],
            'axis': ['AXIS', 'AXISBANK']
        }

        logger.info("Market Intelligence Engine initialized")

    def gather_intelligence(self) -> List[MarketEvent]:
        """
        Gather market intelligence from all sources.

        Returns:
            List of new market events found
        """
        logger.info("Gathering market intelligence")

        new_events = []

        # Gather from news sources
        for source_key, source_config in self.news_sources.items():
            if source_config['enabled']:
                try:
                    events = self._gather_from_news_source(source_key, source_config)
                    new_events.extend(events)
                except Exception as e:
                    logger.error(f"Error gathering from {source_config['name']}: {e}")

        # Gather corporate announcements
        for source_key, source_config in self.corporate_sources.items():
            if source_config['enabled']:
                try:
                    events = self._gather_corporate_announcements(source_key, source_config)
                    new_events.extend(events)
                except Exception as e:
                    logger.error(f"Error gathering corporate announcements from {source_config['name']}: {e}")

        # Filter out already processed events
        new_events = [e for e in new_events if not self._is_already_processed(e)]

        if new_events:
            logger.warning(f"Gathered {len(new_events)} new market intelligence items")
            self.events.extend(new_events)

        return new_events

    def _gather_from_news_source(self, source_key: str, source_config: Dict[str, Any]) -> List[MarketEvent]:
        """Gather intelligence from a news RSS feed."""
        events = []

        if not FEEDPARSER_AVAILABLE:
            logger.info(f"Skipping {source_config['name']} RSS parsing - feedparser not available")
            # Return mock/placeholder events for testing
            if source_key == 'reuters':
                events.append(MarketEvent(
                    event_type='news',
                    title='Market Intelligence Gathering Active',
                    summary='System is monitoring market news and events',
                    source=source_config['name'],
                    url='',
                    timestamp=datetime.now(),
                    sentiment='neutral',
                    impact='low',
                    symbols_affected=[]
                ))
            return events

        try:
            feed = feedparser.parse(source_config['rss_url'])

            for entry in feed.entries[:20]:  # Check last 20 entries
                try:
                    # Parse the entry
                    title = entry.title if hasattr(entry, 'title') else ''
                    summary = entry.summary if hasattr(entry, 'summary') else ''
                    published = entry.published_parsed if hasattr(entry, 'published_parsed') else None

                    # Convert published time
                    if published:
                        timestamp = datetime(*published[:6])
                    else:
                        timestamp = datetime.now()

                    # Only process recent news (last 24 hours)
                    if timestamp < datetime.now() - timedelta(hours=24):
                        continue

                    # Determine if this is market-relevant
                    if self._is_market_relevant(title + ' ' + summary):
                        event = MarketEvent(
                            event_type='news',
                            title=title,
                            summary=summary,
                            source=source_config['name'],
                            url=entry.link if hasattr(entry, 'link') else '',
                            timestamp=timestamp,
                            sentiment=self._analyze_sentiment(title + ' ' + summary),
                            impact=self._determine_impact(title + ' ' + summary),
                            symbols_affected=self._extract_affected_symbols(title + ' ' + summary)
                        )
                        events.append(event)

                except Exception as e:
                    logger.error(f"Error processing news entry: {e}")

        except Exception as e:
            logger.error(f"Error parsing RSS feed for {source_config['name']}: {e}")

        return events

    def _gather_corporate_announcements(self, source_key: str, source_config: Dict[str, Any]) -> List[MarketEvent]:
        """Gather corporate announcements."""
        events = []

        try:
            headers = {
                'User-Agent': 'AurumHarmony Market Intelligence/1.0',
                'Accept': 'application/json'
            }

            if source_key == 'nse_announcements':
                # NSE API call
                response = requests.get(source_config['url'], headers=headers, timeout=30)
                if response.status_code == 200:
                    data = response.json()
                    events = self._parse_nse_announcements(data)
            elif source_key == 'bse_announcements':
                # BSE scraping (simplified)
                events = self._scrape_bse_announcements()

        except Exception as e:
            logger.error(f"Error gathering corporate announcements: {e}")

        return events

    def _parse_nse_announcements(self, data: Dict[str, Any]) -> List[MarketEvent]:
        """Parse NSE corporate announcements."""
        events = []

        if 'data' in data:
            for item in data['data'][:20]:  # Last 20 announcements
                try:
                    event = MarketEvent(
                        event_type='corporate',
                        title=item.get('subject', ''),
                        summary=item.get('details', ''),
                        source='NSE',
                        url=item.get('url', ''),
                        timestamp=datetime.fromisoformat(item.get('date', datetime.now().isoformat())),
                        sentiment='neutral',  # Corporate announcements are typically neutral
                        impact=self._determine_corporate_impact(item.get('subject', '')),
                        symbols_affected=[item.get('symbol', '')] if item.get('symbol') else []
                    )
                    events.append(event)
                except Exception as e:
                    logger.error(f"Error parsing NSE announcement: {e}")

        return events

    def _scrape_bse_announcements(self) -> List[MarketEvent]:
        """Scrape BSE corporate announcements."""
        # Simplified implementation - would need proper scraping
        return []

    def _is_market_relevant(self, text: str) -> bool:
        """Determine if text contains market-relevant information."""
        text_lower = text.lower()

        # Check for Indian market keywords
        market_keywords = [
            'nifty', 'sensex', 'bse', 'nse', 'rupee', 'india', 'indian market',
            'stock', 'shares', 'trading', 'investor', 'ipo', 'fpo', 'merger',
            'acquisition', 'earnings', 'profit', 'loss', 'revenue', 'bank',
            'finance', 'economy', 'gdp', 'inflation', 'rbi', 'sebi'
        ]

        return any(keyword in text_lower for keyword in market_keywords)

    def _analyze_sentiment(self, text: str) -> str:
        """Analyze sentiment of the text."""
        text_lower = text.lower()

        positive_words = ['profit', 'gain', 'rise', 'increase', 'growth', 'surge', 'rally', 'bullish', 'positive']
        negative_words = ['loss', 'fall', 'decline', 'drop', 'crash', 'bearish', 'negative', 'slump', 'crisis']

        positive_count = sum(1 for word in positive_words if word in text_lower)
        negative_count = sum(1 for word in negative_words if word in text_lower)

        if positive_count > negative_count:
            return 'positive'
        elif negative_count > positive_count:
            return 'negative'
        else:
            return 'neutral'

    def _determine_impact(self, text: str) -> str:
        """Determine market impact level."""
        text_lower = text.lower()

        for impact_level, keywords in self.impact_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                return impact_level

        return 'low'

    def _determine_corporate_impact(self, title: str) -> str:
        """Determine impact of corporate announcement."""
        title_lower = title.lower()

        if any(word in title_lower for word in ['merger', 'acquisition', 'delisting', 'bankruptcy']):
            return 'high'
        elif any(word in title_lower for word in ['earnings', 'results', 'dividend', 'split']):
            return 'medium'
        else:
            return 'low'

    def _extract_affected_symbols(self, text: str) -> List[str]:
        """Extract stock symbols mentioned in the text."""
        symbols = []
        text_lower = text.lower()

        for company, company_symbols in self.company_symbols.items():
            if company in text_lower:
                symbols.extend(company_symbols)

        # Extract any NSE/BSE symbols using regex
        symbol_pattern = r'\b[A-Z]{2,10}\b'
        found_symbols = re.findall(symbol_pattern, text)
        symbols.extend([s for s in found_symbols if len(s) >= 2 and len(s) <= 10])

        return list(set(symbols))  # Remove duplicates

    def _is_already_processed(self, event: MarketEvent) -> bool:
        """Check if an event has already been processed."""
        for existing in self.events:
            if (existing.source == event.source and
                existing.title == event.title and
                abs((existing.timestamp - event.timestamp).total_seconds()) < 300):  # 5 min tolerance
                return True
        return False

    def get_high_impact_events(self) -> List[MarketEvent]:
        """Get all high-impact market events."""
        return [e for e in self.events if e.impact == 'high' and not e.processed]

    def get_events_by_type(self, event_type: str) -> List[MarketEvent]:
        """Get events by type (news, corporate, economic)."""
        return [e for e in self.events if e.event_type == event_type]

    def get_recent_events(self, hours: int = 24) -> List[MarketEvent]:
        """Get events from the last N hours."""
        cutoff = datetime.now() - timedelta(hours=hours)
        return [e for e in self.events if e.timestamp >= cutoff]

    def mark_event_processed(self, event: MarketEvent):
        """Mark an event as processed."""
        event.processed = True
        logger.info(f"Marked market event as processed: {event.title}")

    def get_market_sentiment(self) -> Dict[str, Any]:
        """Get overall market sentiment based on recent events."""
        recent_events = self.get_recent_events(24)

        if not recent_events:
            return {'overall': 'neutral', 'confidence': 0.5}

        sentiment_counts = {'positive': 0, 'negative': 0, 'neutral': 0}

        for event in recent_events:
            sentiment_counts[event.sentiment] += 1

        # Weight by impact
        weighted_sentiment = 0
        total_weight = 0

        for event in recent_events:
            weight = {'high': 3, 'medium': 2, 'low': 1}[event.impact]
            sentiment_value = {'positive': 1, 'neutral': 0, 'negative': -1}[event.sentiment]

            weighted_sentiment += sentiment_value * weight
            total_weight += weight

        if total_weight > 0:
            avg_sentiment = weighted_sentiment / total_weight

            if avg_sentiment > 0.2:
                overall = 'positive'
            elif avg_sentiment < -0.2:
                overall = 'negative'
            else:
                overall = 'neutral'

            confidence = min(abs(avg_sentiment), 1.0)
        else:
            overall = 'neutral'
            confidence = 0.5

        return {
            'overall': overall,
            'confidence': confidence,
            'recent_events': len(recent_events),
            'sentiment_breakdown': sentiment_counts
        }

    def _check_economic_news(self) -> List[MarketEvent]:
        """Check economic news that could affect markets."""
        # Placeholder - would integrate with news APIs
        # For now, return mock events to demonstrate functionality
        return [
            MarketEvent(
                event_type='economic',
                title='Economic Indicator Monitoring Active',
                summary='System monitoring GDP, inflation, employment, and trade data',
                source='System',
                url='',
                timestamp=datetime.now(),
                sentiment='neutral',
                impact='medium',
                symbols_affected=[]
            )
        ]

    def _check_corporate_announcements(self) -> List[MarketEvent]:
        """Check corporate announcements."""
        # Placeholder - would integrate with corporate news APIs
        return []

    def _check_market_events(self) -> List[MarketEvent]:
        """Check market-moving events."""
        # Placeholder - would integrate with event calendars
        return []
