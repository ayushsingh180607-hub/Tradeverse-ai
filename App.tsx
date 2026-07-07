import React, { useState, useEffect } from "react";
import { UserState, Stock, OptionContract, MutualFund, Ipo, LeaderboardUser, SocialPost } from "./types";
import Header from "./components/Header";
import Watchlist from "./components/Watchlist";
import TradingPanel from "./components/TradingPanel";
import PortfolioAnalytics from "./components/PortfolioAnalytics";
import AICoachTab from "./components/AICoachTab";
import LearningZone from "./components/LearningZone";
import SocialContestTab from "./components/SocialContestTab";
import AlertsCalendarTab from "./components/AlertsCalendarTab";
import { Eye, BookOpen, Brain, Users, Bell, BarChart3, HelpCircle, Bot, X } from "lucide-react";

export default function App() {
  const [activeTab, setActiveTab] = useState<"WATCHLIST" | "PORTFOLIO" | "COACH" | "LEARN" | "SOCIAL" | "ALERTS">("WATCHLIST");
  const [language, setLanguage] = useState<"en" | "hi">("en");

  // Server state data
  const [user, setUser] = useState<UserState | null>(null);
  const [stocks, setStocks] = useState<Stock[]>([]);
  const [optionsChain, setOptionsChain] = useState<OptionContract[]>([]);
  const [mutualFunds, setMutualFunds] = useState<MutualFund[]>([]);
  const [ipos, setIpos] = useState<Ipo[]>([]);
  const [news, setNews] = useState<any[]>([]);
  const [leaderboard, setLeaderboard] = useState<LeaderboardUser[]>([]);
  const [socialPosts, setSocialPosts] = useState<SocialPost[]>([]);

  // Toggles & Selection
  const [selectedStock, setSelectedStock] = useState<Stock | null>(null);
  const [selectedOrderType, setSelectedOrderType] = useState<"BUY" | "SELL">("BUY");
  const [showTradePanel, setShowTradePanel] = useState(false);
  const [voiceResult, setVoiceResult] = useState("");

  const t = {
    en: {
      watchlist: "Terminal",
      portfolio: "Portfolio",
      coach: "AI Coach",
      learning: "Learning Zone",
      social: "Contests",
      alerts: "Alerts & SIP",
      newsHeader: "Market Bulletin",
      errorLoading: "Synchronizing with TradeVerse server...",
      welcomeTitle: "Namaste, Trader!",
      welcomeDesc: "Welcome back to your PaperBull cockpit. Tap any scrip to verify live technical levels."
    },
    hi: {
      watchlist: "टर्मिनल",
      portfolio: "पोर्टफोलियो",
      coach: "एआई कोच",
      learning: "लर्निंग ज़ोन",
      social: "प्रतियोगिताएं",
      alerts: "अलर्ट और एसआईपी",
      newsHeader: "बाजार बुलेटिन",
      errorLoading: "ट्रेडवर्स सर्वर के साथ सिंक्रनाइज़ हो रहा है...",
      welcomeTitle: "नमस्ते, ट्रेडर!",
      welcomeDesc: "आपके पेपरबुल कॉकपिट में आपका स्वागत है। लाइव स्तरों को सत्यापित करने के लिए किसी भी स्क्रिप्ट पर टैप करें।"
    }
  }[language];

  // Fetch functions
  const fetchUser = async () => {
    try {
      const res = await fetch("/api/user");
      if (res.ok) {
        const data = await res.json();
        setUser(data);
      }
    } catch (err) {
      console.error("Error fetching user data:", err);
    }
  };

  const fetchMarketData = async () => {
    try {
      const res = await fetch("/api/market-data");
      if (res.ok) {
        const data = await res.json();
        setStocks(data.stocks);
        setOptionsChain(data.optionsChain);
        setNews(data.news);
      }
    } catch (err) {
      console.error("Error fetching market data:", err);
    }
  };

  const fetchLearningData = async () => {
    try {
      const res = await fetch("/api/courses");
      if (res.ok) {
        const data = await res.json();
        setMutualFunds(data.mutualFunds);
        setIpos(data.ipos);
      }
    } catch (err) {
      console.error("Error fetching learning details:", err);
    }
  };

  const fetchLeaderboard = async () => {
    try {
      const res = await fetch("/api/leaderboard");
      if (res.ok) {
        const data = await res.json();
        setLeaderboard(data.leaderboard);
      }
    } catch (err) {
      console.error("Error fetching leader standings:", err);
    }
  };

  const fetchSocialPosts = async () => {
    try {
      const res = await fetch("/api/social");
      if (res.ok) {
        const data = await res.json();
        setSocialPosts(data.posts);
      }
    } catch (err) {
      console.error("Error fetching social feed:", err);
    }
  };

  // Trigger initial loaders
  useEffect(() => {
    fetchUser();
    fetchMarketData();
    fetchLearningData();
    fetchLeaderboard();
    fetchSocialPosts();

    // Setup polling every 4 seconds for simulated live ticking
    const interval = setInterval(() => {
      fetchMarketData();
      // Occasionally update user balance details for live current values
      fetchUser();
    }, 4000);

    return () => clearInterval(interval);
  }, []);

  // Post Actions
  const handleExecuteTrade = async (tradeDetails: {
    symbol: string;
    type: "BUY" | "SELL";
    qty: number;
    product: "INTRADAY" | "DELIVERY";
    category: "EQUITY" | "OPTION" | "MUTUAL_FUND" | "IPO";
    customPrice?: number;
  }) => {
    const res = await fetch("/api/order", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(tradeDetails)
    });

    if (!res.ok) {
      const errData = await res.json();
      throw new Error(errData.error || "Order execution failed");
    }

    // Refresh state
    await fetchUser();
    await fetchLeaderboard();
    await fetchSocialPosts();
  };

  const handleToggleWatchlist = async (symbol: string) => {
    try {
      const res = await fetch("/api/watchlist/toggle", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ symbol })
      });
      if (res.ok) {
        fetchUser();
      }
    } catch (err) {
      console.error("Failed to toggle watchlist symbol:", err);
    }
  };

  const handleAddJournalEntry = async (entry: {
    title: string;
    notes: string;
    emotion: "CALM" | "GREEDY" | "FEARFUL" | "EXCITED" | "REGRETFUL";
  }) => {
    const res = await fetch("/api/journal", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(entry)
    });

    if (!res.ok) {
      throw new Error("Journal save failed");
    }

    await fetchUser();
  };

  const handleCompleteQuiz = async (courseId: string, score: number, totalQuestions: number) => {
    try {
      const res = await fetch("/api/quiz/complete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ courseId, score, totalQuestions })
      });
      if (res.ok) {
        fetchUser();
      }
    } catch (err) {
      console.error("Quiz result submit failed:", err);
    }
  };

  const handleSetAlert = async (symbol: string, targetPrice: number, condition: "ABOVE" | "BELOW") => {
    const res = await fetch("/api/alerts", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ symbol, targetPrice, condition })
    });

    if (!res.ok) {
      throw new Error("Alert setting failed");
    }

    await fetchUser();
  };

  const handleShareToFeed = async (postContent: string) => {
    const res = await fetch("/api/social/post", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: postContent })
    });

    if (!res.ok) {
      throw new Error("Sharing to feed failed");
    }

    await fetchSocialPosts();
    await fetchUser();
  };

  const handleVoiceQuery = async (query: string) => {
    try {
      const res = await fetch("/api/voice-assistant", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query })
      });
      if (res.ok) {
        const data = await res.json();
        setVoiceResult(data.answer);
      }
    } catch (err) {
      console.error("Voice assistant query failed:", err);
    }
  };

  const handleAskCoachChat = async (message: string): Promise<string> => {
    const res = await fetch("/api/ai-coach/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message })
    });

    if (res.ok) {
      const data = await res.json();
      return data.response;
    }
    return "I am currently analyzing standard technical indicators. Let me know if you want to inspect options contracts!";
  };

  const handleAnalyzePortfolio = async (): Promise<string> => {
    const res = await fetch("/api/ai-coach/analyze", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        portfolioSummary: {
          balance: user?.balance,
          portfolioValue: user?.portfolioValue,
          positionsCount: user?.positions?.length
        }
      })
    });

    if (res.ok) {
      const data = await res.json();
      return data.response;
    }
    return "Unable to compile custom risk profiles. Try adding standard Bluechip stocks first.";
  };

  if (!user || stocks.length === 0) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center text-slate-400 font-mono">
        <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-400 mb-4 animate-spin">
          <Bot className="w-6 h-6" />
        </div>
        <p>{t.errorLoading}</p>
      </div>
    );
  }

  // Live indices dictionary
  const indexes = {
    nifty: { name: "Nifty 50", price: 24320.50, change: 85.20, changePercent: 0.35, history: [] },
    sensex: { name: "SENSEX", price: 79540.80, change: 245.10, changePercent: 0.31, history: [] },
    banknifty: { name: "Bank Nifty", price: 52140.30, change: -110.40, changePercent: -0.21, history: [] }
  };

  return (
    <div className="min-h-screen bg-slate-950 font-sans text-slate-100 flex flex-col justify-between">
      <div>
        {/* Core Header */}
        <Header
          user={user}
          indexes={indexes}
          language={language}
          setLanguage={setLanguage}
          onVoiceQuery={handleVoiceQuery}
          voiceResult={voiceResult}
        />

        {/* Dashboard Navigation */}
        <nav className="bg-slate-900 border-b border-slate-800/80 sticky top-[95px] z-30">
          <div className="max-w-7xl mx-auto px-4 overflow-x-auto scrollbar-none flex gap-1 py-3">
            {[
              { id: "WATCHLIST", label: t.watchlist, icon: Eye },
              { id: "PORTFOLIO", label: t.portfolio, icon: BarChart3 },
              { id: "COACH", label: t.coach, icon: Brain },
              { id: "LEARN", label: t.learning, icon: BookOpen },
              { id: "SOCIAL", label: t.social, icon: Users },
              { id: "ALERTS", label: t.alerts, icon: Bell }
            ].map(tab => {
              const isActive = activeTab === tab.id;
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => {
                    setActiveTab(tab.id as any);
                    setSelectedStock(null);
                  }}
                  className={`px-4.5 py-2 rounded-xl text-xs font-bold font-sans transition flex items-center gap-2 whitespace-nowrap ${isActive ? "bg-emerald-500 text-slate-950 shadow-lg shadow-emerald-500/10" : "text-slate-400 hover:text-slate-200 hover:bg-slate-850"}`}
                >
                  <Icon className="w-4 h-4 shrink-0" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>
        </nav>

        {/* Welcome Message row */}
        <div className="max-w-7xl mx-auto px-4 mt-6">
          <div className="bg-slate-900/40 border border-slate-800/60 p-4.5 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-sm font-bold text-slate-100 font-sans flex items-center gap-1.5">
                <span>{t.welcomeTitle}</span>
              </h2>
              <p className="text-xs text-slate-400 font-sans mt-0.5">{t.welcomeDesc}</p>
            </div>

            {/* Quick Paper Orders Button */}
            <button
              onClick={() => {
                setSelectedStock(null);
                setTradeTypeFromWatch(stocks[0], "BUY");
              }}
              className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 hover:bg-emerald-500/20 font-bold text-xs px-4 py-2 rounded-xl transition"
            >
              + Quick Trade Scrip
            </button>
          </div>
        </div>

        {/* Core Tab Routing Panels */}
        <main className="max-w-7xl mx-auto px-4 py-6">
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
            
            {/* Left/Main Column - Contextual Tab Render */}
            <div className="xl:col-span-2 space-y-6">
              {activeTab === "WATCHLIST" && (
                <Watchlist
                  stocks={stocks}
                  watchlistSymbols={user.watchlist}
                  onToggleWatchlist={handleToggleWatchlist}
                  onSelectTrade={(stock, type) => setTradeTypeFromWatch(stock, type)}
                  language={language}
                />
              )}

              {activeTab === "PORTFOLIO" && (
                <PortfolioAnalytics
                  user={user}
                  onAddJournalEntry={handleAddJournalEntry}
                  onRefreshUser={fetchUser}
                  language={language}
                />
              )}

              {activeTab === "COACH" && (
                <AICoachTab
                  user={user}
                  onAnalyzePortfolio={handleAnalyzePortfolio}
                  onAskCoachChat={handleAskCoachChat}
                  language={language}
                />
              )}

              {activeTab === "LEARN" && (
                <LearningZone
                  user={user}
                  courses={learningCourses}
                  onCompleteQuiz={handleCompleteQuiz}
                  language={language}
                />
              )}

              {activeTab === "SOCIAL" && (
                <SocialContestTab
                  user={user}
                  leaderboard={leaderboard}
                  socialPosts={socialPosts}
                  onShareToFeed={handleShareToFeed}
                  language={language}
                />
              )}

              {activeTab === "ALERTS" && (
                <AlertsCalendarTab
                  user={user}
                  stocks={stocks}
                  onSetAlert={handleSetAlert}
                  language={language}
                />
              )}
            </div>

            {/* Right Column - Secondary Widgets (Market Bulletin & Fast Trade panel) */}
            <div className="space-y-6 xl:col-span-1">
              
              {/* Custom floating Trade Box / Detailer */}
              {showTradePanel ? (
                <div className="relative animate-fade-in">
                  <button
                    onClick={() => setShowTradePanel(false)}
                    className="absolute top-4 right-4 text-slate-500 hover:text-white z-10 transition p-1 rounded-lg bg-slate-950/40"
                  >
                    <X className="w-4 h-4" />
                  </button>
                  <TradingPanel
                    user={user}
                    stocks={stocks}
                    optionsChain={optionsChain}
                    mutualFunds={simulatedMutualFunds}
                    ipos={simulatedIpos}
                    selectedStock={selectedStock}
                    selectedOrderType={selectedOrderType}
                    onExecuteTrade={handleExecuteTrade}
                    onClose={() => setShowTradePanel(false)}
                    language={language}
                  />
                </div>
              ) : (
                /* Static Fast Trade Suggestor when Panel is inactive */
                <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-xl space-y-3.5">
                  <h3 className="text-sm font-bold text-slate-200 font-sans flex items-center gap-1.5">
                    <span>⚡ Quick Trade Simulator</span>
                  </h3>
                  <p className="text-xs text-slate-400 font-sans leading-relaxed">
                    Tap any BUY/SELL buttons in the terminal, option chains, or mutual funds list to launch the active trade ticket drawer instantly.
                  </p>
                  <button
                    onClick={() => {
                      setSelectedStock(stocks[0]);
                      setSelectedOrderType("BUY");
                      setShowTradePanel(true);
                    }}
                    className="w-full bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-xs py-2.5 rounded-xl transition"
                  >
                    Launch Trading Deck
                  </button>
                </div>
              )}

              {/* Market News Bulletins */}
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-xl space-y-4">
                <div className="flex items-center justify-between border-b border-slate-800 pb-2">
                  <h3 className="text-sm font-bold font-sans text-slate-100">{t.newsHeader}</h3>
                  <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></span>
                </div>

                <div className="space-y-3 max-h-64 overflow-y-auto scrollbar-none">
                  {news.map(item => (
                    <div key={item.id} className="group cursor-pointer space-y-1">
                      <span className="text-[9px] text-slate-500 font-mono block">
                        {item.source} • {item.time}
                      </span>
                      <h4 className="text-xs font-bold leading-snug text-slate-300 group-hover:text-emerald-400 transition font-sans">
                        {item.title}
                      </h4>
                    </div>
                  ))}
                </div>
              </div>
            </div>

          </div>
        </main>
      </div>

      {/* Humble craft footers */}
      <footer className="bg-slate-950 border-t border-slate-900 py-6 text-center text-slate-500 text-[11px] font-mono mt-12">
        <p>TradeVerse AI © 2026 • Real-time paper trading simulator utilizing advanced Indian market seeds</p>
        <p className="text-slate-600 mt-1">Simulated on high-performance Cloud Run workspace • Crafted with pride</p>
      </footer>
    </div>
  );

  // Helper setter
  function setTradeTypeFromWatch(stock: Stock | null, type: "BUY" | "SELL") {
    setSelectedStock(stock);
    setSelectedOrderType(type);
    setShowTradePanel(true);
  }
}

// Simulated data models that mirror server preseeders to prevent loading flickers
const simulatedMutualFunds = [
  { id: "mf1", name: "Parag Parikh Flexi Cap Direct", nav: 72.40, category: "EQUITY" as const, return3Y: 22.4, risk: "HIGH" as const, minSip: 1000 },
  { id: "mf2", name: "SBI Bluechip Direct Plan", nav: 98.15, category: "INDEX" as const, return3Y: 15.6, risk: "MODERATE" as const, minSip: 500 },
  { id: "mf3", name: "HDFC Liquid Fund Direct", nav: 4620.50, category: "DEBT" as const, return3Y: 6.8, risk: "LOW" as const, minSip: 5000 },
  { id: "mf4", name: "Mirae Asset Large Cap Fund", nav: 114.30, category: "EQUITY" as const, return3Y: 18.2, risk: "HIGH" as const, minSip: 1000 }
];

const simulatedIpos = [
  { id: "ipo1", companyName: "Zinka Logistics (Blackbuck) IPO", priceBand: "₹250 - ₹273", lotSize: 54, issueSize: "₹1,114 Cr", openDate: "2026-07-05", closeDate: "2026-07-10", status: "OPEN" as const },
  { id: "ipo2", companyName: "NTPC Green Energy IPO", priceBand: "₹102 - ₹108", lotSize: 138, issueSize: "₹10,000 Cr", openDate: "2026-07-12", closeDate: "2026-07-17", status: "OPEN" as const },
  { id: "ipo3", companyName: "Hyundai Motor India Ltd", priceBand: "₹1860 - ₹1960", lotSize: 7, issueSize: "₹27,870 Cr", openDate: "2026-06-15", closeDate: "2026-06-18", status: "LISTED" as const }
];

const learningCourses = [
  {
    id: "c1",
    title: "Stock Market Basics (Beginner)",
    description: "Learn the foundational concepts of public trading, NSE/BSE stock exchanges, and how prices move.",
    difficulty: "BEGINNER" as const,
    lessons: [
      { id: "c1_l1", title: "What is a Share?", content: "A share represents unit ownership in a company. When you purchase a share of Reliance or TCS, you own a tiny fraction of that company, becoming a shareholder." },
      { id: "c1_l2", title: "NSE vs. BSE", content: "The National Stock Exchange (NSE) is the leading technological bourse in Mumbai, famous for the Nifty 50 index. The Bombay Stock Exchange (BSE) is Asia's oldest exchange, tracking the SENSEX index." },
      { id: "c1_l3", title: "Intraday vs. Delivery", content: "Intraday trading means buying and selling a stock within the same day before the market closes at 3:30 PM. Delivery trading involves buying a stock and holding it overnight or for years in your demat account." }
    ],
    quizzes: [
      { id: "q1_1", question: "At what time does the regular Indian stock market close daily?", options: ["3:15 PM", "3:30 PM", "4:00 PM", "5:00 PM"], correctIndex: 1, explanation: "Regular market hours are 9:15 AM to 3:30 PM, Monday to Friday." },
      { id: "q1_2", question: "What does NSE stand for in the Indian markets?", options: ["National Stock Exchange", "New Share Exchange", "Nippon Stock Equity", "National Security Exchange"], correctIndex: 0, explanation: "NSE stands for the National Stock Exchange of India." }
    ]
  },
  {
    id: "c2",
    title: "Technical Analysis & Charting (Intermediate)",
    description: "Understand candlestick charts, support & resistance levels, and key indicators like RSI & MACD.",
    difficulty: "INTERMEDIATE" as const,
    lessons: [
      { id: "c2_l1", title: "Understanding Candlesticks", content: "A candlestick represents price movement in a specific period (e.g., 5 min, 1 day). Green candles show prices closing higher than they opened, while red candles indicate a lower close. Key components are the body and shadows (wicks)." },
      { id: "c2_l2", title: "Support & Resistance", content: "Support is the price level where a stock tends to stop falling as buying interest increases. Resistance is the price ceiling where selling pressure stops the stock from climbing further." },
      { id: "c2_l3", title: "Relative Strength Index (RSI)", content: "RSI is a momentum oscillator measuring price velocity between 0 and 100. Traditionally, a stock is overbought if RSI goes above 70 and oversold if it drops below 30." }
    ],
    quizzes: [
      { id: "q2_1", question: "If a candlestick has a long lower shadow and tiny body at the top, what pattern is this?", options: ["Doji", "Hammer", "Shooting Star", "Bearish Engulfing"], correctIndex: 1, explanation: "A Hammer candlestick forms at support levels, signaling bullish rejection of lower prices." },
      { id: "q2_2", question: "An RSI value of 82 typically suggests a stock is in which condition?", options: ["Oversold", "Fairly Valued", "Overbought", "Extremely cheap"], correctIndex: 2, explanation: "RSI values above 70 indicate overbought conditions, hinting a correction might happen." }
    ]
  },
  {
    id: "c3",
    title: "Futures & Options - F&O (Advanced)",
    description: "Deep dive into options trading, Call (CE) & Put (PE) options, Strike Prices, and Options Chain.",
    difficulty: "ADVANCED" as const,
    lessons: [
      { id: "c3_l1", title: "What are Futures & Options?", content: "F&O are derivative contracts deriving value from an underlying stock or index (like Nifty). Futures bind you to buy/sell at a set rate, while Options give you the right (but not obligation) to trade." },
      { id: "c3_l2", title: "Call (CE) vs. Put (PE)", content: "In India, Call Options are called Call European (CE) and Put Options are Put European (PE). Buy CE if you think Nifty will rise. Buy PE if you expect Nifty to drop." },
      { id: "c3_l3", title: "Option Expiries & Option Chain", content: "F&O contracts expire periodically (weekly for indexes, monthly for equities). The Option Chain displays all strikes, Open Interest (OI), bid/ask, and premiums for both CE and PE." }
    ],
    quizzes: [
      { id: "q3_1", question: "What does CE represent in the Indian options chain?", options: ["Commodity Equity", "Call European", "Cash Equity", "Capital Earnings"], correctIndex: 1, explanation: "CE stands for Call European, representing call options traded on Indian exchanges." },
      { id: "q3_2", question: "If you buy a Put Option (PE), you profit when the underlying asset's price does what?", options: ["Stays Flat", "Rises", "Falls", "Doubles in value"], correctIndex: 2, explanation: "Puts (PE) increase in value when the underlying asset declines in price." }
    ]
  }
];
