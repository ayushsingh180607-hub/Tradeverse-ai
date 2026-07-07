import express from "express";
import path from "path";
import fs from "fs";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

// Initialize Gemini SDK with telemetry headers
let ai: any = null;
if (process.env.GEMINI_API_KEY) {
  try {
    ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        }
      }
    });
    console.log("GoogleGenAI initialized successfully on server-side.");
  } catch (err) {
    console.error("Error initializing GoogleGenAI:", err);
  }
} else {
  console.log("GEMINI_API_KEY is not defined. AI Coach will run with rich local simulation responses.");
}

const DB_FILE = path.join(process.cwd(), "db-store.json");

// Default initial state
const defaultUserState = {
  balance: 1000000, // ₹10,00,000
  portfolioValue: 0,
  xp: 150,
  level: 1,
  badges: ["Novice Trader"],
  watchlist: ["RELIANCE", "TCS", "HDFCBANK", "INFY", "TATAMOTORS"],
  positions: [
    {
      symbol: "RELIANCE",
      qty: 20,
      avgPrice: 2450.0,
      currentPrice: 2480.0,
      product: "DELIVERY" as const,
      category: "EQUITY" as const
    }
  ],
  orders: [
    {
      id: "o1",
      symbol: "RELIANCE",
      type: "BUY" as const,
      product: "DELIVERY" as const,
      qty: 20,
      price: 2450.0,
      timestamp: new Date(Date.now() - 3600000 * 2).toISOString(),
      category: "EQUITY" as const,
      status: "COMPLETED" as const
    }
  ],
  quizzesCompleted: [] as string[],
  certificates: [] as string[],
  alerts: [
    {
      id: "a1",
      symbol: "RELIANCE",
      targetPrice: 2500,
      condition: "ABOVE" as "ABOVE" | "BELOW",
      isActive: true,
      isTriggered: false,
      timestamp: new Date().toISOString()
    }
  ],
  journal: [
    {
      id: "j1",
      date: "2026-07-06",
      title: "First Indian Trading Journal Entry",
      notes: "Started with ₹10 Lakh virtual balance. Bought 20 shares of Reliance Industries at 2450 based on a breakout above local resistance on the 15-minute timeframe. P&L looks strong so far.",
      tradesReferenced: ["o1"],
      emotion: "CALM" as const
    }
  ],
  following: ["Aniket_Bull", "Neha_Invests", "OptionTraderPro"]
};

// Load or create state
let userState = { ...defaultUserState };
if (fs.existsSync(DB_FILE)) {
  try {
    const data = fs.readFileSync(DB_FILE, "utf-8");
    userState = { ...defaultUserState, ...JSON.parse(data) };
  } catch (err) {
    console.error("Failed to read db-store.json, resetting to default.", err);
  }
}

function saveState() {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(userState, null, 2), "utf-8");
  } catch (err) {
    console.error("Failed to save state to db-store.json:", err);
  }
}

// Market stock prices simulation seed
const initialStocks = [
  { symbol: "RELIANCE", name: "Reliance Industries Ltd.", price: 2480.25, prevClose: 2451.10, sector: "Energy", high: 2495.0, low: 2442.0, volume: 1520000, change: 0, changePercent: 0 },
  { symbol: "TCS", name: "Tata Consultancy Services Ltd.", price: 3820.60, prevClose: 3845.0, sector: "Technology", high: 3860.0, low: 3801.0, volume: 850000, change: 0, changePercent: 0 },
  { symbol: "HDFCBANK", name: "HDFC Bank Ltd.", price: 1625.40, prevClose: 1612.30, sector: "Finance", high: 1632.0, low: 1605.5, volume: 2200000, change: 0, changePercent: 0 },
  { symbol: "INFY", name: "Infosys Ltd.", price: 1542.10, prevClose: 1560.0, sector: "Technology", high: 1565.0, low: 1533.0, volume: 1100000, change: 0, changePercent: 0 },
  { symbol: "ICICIBANK", name: "ICICI Bank Ltd.", price: 1120.75, prevClose: 1115.0, sector: "Finance", high: 1128.0, low: 1108.0, volume: 1900000, change: 0, changePercent: 0 },
  { symbol: "SBIN", name: "State Bank of India", price: 840.50, prevClose: 848.20, sector: "Finance", high: 852.0, low: 836.0, volume: 3400000, change: 0, changePercent: 0 },
  { symbol: "TATAMOTORS", name: "Tata Motors Ltd.", price: 965.80, prevClose: 942.10, sector: "Automobile", high: 978.0, low: 938.5, volume: 2800000, change: 0, changePercent: 0 },
  { symbol: "ITC", name: "ITC Ltd.", price: 432.20, prevClose: 430.50, sector: "FMCG", high: 435.5, low: 428.0, volume: 4100000, change: 0, changePercent: 0 },
  { symbol: "LT", name: "Larsen & Toubro Ltd.", price: 3510.15, prevClose: 3525.0, sector: "Construction", high: 3540.0, low: 3495.0, volume: 480000, change: 0, changePercent: 0 },
  { symbol: "BHARTIARTL", name: "Bharti Airtel Ltd.", price: 1412.30, prevClose: 1402.0, sector: "Telecom", high: 1422.0, low: 1395.0, volume: 950000, change: 0, changePercent: 0 }
];

// In-memory persistent history mapping
const stockHistory: Record<string, number[]> = {};
initialStocks.forEach(s => {
  stockHistory[s.symbol] = Array.from({ length: 15 }, (_, i) => {
    const factor = 1 + (Math.sin(i * 0.5) * 0.03) + (Math.cos(i * 0.8) * 0.01);
    return parseFloat((s.prevClose * factor).toFixed(2));
  });
});

let marketIndexes = {
  nifty: { name: "Nifty 50", price: 24320.50, change: 85.20, changePercent: 0.35, history: [24100, 24150, 24080, 24190, 24220, 24180, 24320] },
  sensex: { name: "SENSEX", price: 79540.80, change: 245.10, changePercent: 0.31, history: [78900, 79100, 78850, 79220, 79350, 79200, 79540] },
  banknifty: { name: "Bank Nifty", price: 52140.30, change: -110.40, changePercent: -0.21, history: [52300, 52400, 52180, 52290, 52350, 52250, 52140] }
};

// Simulate continuous market ticking
setInterval(() => {
  initialStocks.forEach(s => {
    // Random fluctuation of max +/- 0.3%
    const changePct = (Math.random() - 0.49) * 0.005; // slightly upward bias
    s.price = parseFloat((s.price * (1 + changePct)).toFixed(2));
    const totalChange = s.price - s.prevClose;
    s.change = parseFloat(totalChange.toFixed(2));
    s.changePercent = parseFloat(((totalChange / s.prevClose) * 100).toFixed(2));
    if (s.price > s.high) s.high = s.price;
    if (s.price < s.low) s.low = s.price;
    s.volume += Math.floor(Math.random() * 500);
  });

  // Fluctuate indexes
  const niftyChange = (Math.random() - 0.48) * 10;
  marketIndexes.nifty.price = parseFloat((marketIndexes.nifty.price + niftyChange).toFixed(2));
  marketIndexes.nifty.change = parseFloat((marketIndexes.nifty.price - 24235.30).toFixed(2));
  marketIndexes.nifty.changePercent = parseFloat(((marketIndexes.nifty.change / 24235.30) * 100).toFixed(2));

  const sensexChange = (Math.random() - 0.48) * 40;
  marketIndexes.sensex.price = parseFloat((marketIndexes.sensex.price + sensexChange).toFixed(2));
  marketIndexes.sensex.change = parseFloat((marketIndexes.sensex.price - 79295.70).toFixed(2));
  marketIndexes.sensex.changePercent = parseFloat(((marketIndexes.sensex.change / 79295.70) * 100).toFixed(2));

  const bankniftyChange = (Math.random() - 0.51) * 30; // slightly downward bias today
  marketIndexes.banknifty.price = parseFloat((marketIndexes.banknifty.price + bankniftyChange).toFixed(2));
  marketIndexes.banknifty.change = parseFloat((marketIndexes.banknifty.price - 52250.70).toFixed(2));
  marketIndexes.banknifty.changePercent = parseFloat(((marketIndexes.banknifty.change / 52250.70) * 100).toFixed(2));

  // Check and process price alerts
  userState.alerts.forEach(alert => {
    if (alert.isActive && !alert.isTriggered) {
      const stock = initialStocks.find(s => s.symbol === alert.symbol);
      if (stock) {
        if (alert.condition === "ABOVE" && stock.price >= alert.targetPrice) {
          alert.isTriggered = true;
          alert.isActive = false;
          console.log(`Alert Triggered: ${alert.symbol} is above ${alert.targetPrice} (Current: ${stock.price})`);
        } else if (alert.condition === "BELOW" && stock.price <= alert.targetPrice) {
          alert.isTriggered = true;
          alert.isActive = false;
          console.log(`Alert Triggered: ${alert.symbol} is below ${alert.targetPrice} (Current: ${stock.price})`);
        }
      }
    }
  });
}, 4000);

// Courses data
const courses = [
  {
    id: "c1",
    title: "Stock Market Basics (Beginner)",
    description: "Learn the foundational concepts of public trading, NSE/BSE stock exchanges, and how prices move.",
    difficulty: "BEGINNER",
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
    difficulty: "INTERMEDIATE",
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
    difficulty: "ADVANCED",
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

// Seeded Mutual Funds
const mutualFunds = [
  { id: "mf1", name: "Parag Parikh Flexi Cap Direct", nav: 72.40, category: "EQUITY", return3Y: 22.4, risk: "HIGH", minSip: 1000 },
  { id: "mf2", name: "SBI Bluechip Direct Plan", nav: 98.15, category: "INDEX", return3Y: 15.6, risk: "MODERATE", minSip: 500 },
  { id: "mf3", name: "HDFC Liquid Fund Direct", nav: 4620.50, category: "DEBT", return3Y: 6.8, risk: "LOW", minSip: 5000 },
  { id: "mf4", name: "Mirae Asset Large Cap Fund", nav: 114.30, category: "EQUITY", return3Y: 18.2, risk: "HIGH", minSip: 1000 }
];

// Seeded IPOs
const ipos = [
  { id: "ipo1", companyName: "Zinka Logistics (Blackbuck) IPO", priceBand: "₹250 - ₹273", lotSize: 54, issueSize: "₹1,114 Cr", openDate: "2026-07-05", closeDate: "2026-07-10", status: "OPEN" },
  { id: "ipo2", companyName: "NTPC Green Energy IPO", priceBand: "₹102 - ₹108", lotSize: 138, issueSize: "₹10,000 Cr", openDate: "2026-07-12", closeDate: "2026-07-17", status: "OPEN" },
  { id: "ipo3", companyName: "Hyundai Motor India Ltd", priceBand: "₹1860 - ₹1960", lotSize: 7, issueSize: "₹27,870 Cr", openDate: "2026-06-15", closeDate: "2026-06-18", status: "LISTED" }
];

// Social Feed (preseeded)
let socialPosts = [
  {
    id: "post1",
    username: "Aniket_Bull",
    avatarUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=100&q=80",
    timestamp: new Date(Date.now() - 3600000 * 4).toISOString(),
    content: "Nifty forming a beautiful Cup and Handle pattern on the 4-hour chart. Watch out for a breakout above 24,400! Longed Tata Motors today, momentum is extremely strong in EV segment.",
    tradeShare: {
      symbol: "TATAMOTORS",
      type: "BUY" as const,
      price: 955.50,
      pnl: 10300
    },
    likes: 24,
    comments: [
      { id: "sc1", username: "Neha_Invests", content: "Agree on Tata Motors. RSI looks very stable on daily.", timestamp: new Date(Date.now() - 3600000 * 3).toISOString() }
    ]
  },
  {
    id: "post2",
    username: "OptionTraderPro",
    avatarUrl: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=100&q=80",
    timestamp: new Date(Date.now() - 3600000 * 12).toISOString(),
    content: "Writing weekly Put options at 24,100 strike PE on Nifty. Open Interest (OI) concentration here is heavy, acting as absolute concrete support.",
    likes: 15,
    comments: []
  }
];

// Options Chain contracts simulation
function generateOptionsChain() {
  const basePrice = Math.round(marketIndexes.nifty.price / 100) * 100;
  const strikes = [basePrice - 200, basePrice - 100, basePrice, basePrice + 100, basePrice + 200];
  
  return strikes.map(strike => {
    const isITM_call = strike < marketIndexes.nifty.price;
    const isITM_put = strike > marketIndexes.nifty.price;
    
    const callPremium = isITM_call 
      ? parseFloat(((marketIndexes.nifty.price - strike) + Math.random() * 30 + 10).toFixed(2))
      : parseFloat((Math.random() * 40 + 5).toFixed(2));
      
    const putPremium = isITM_put 
      ? parseFloat(((strike - marketIndexes.nifty.price) + Math.random() * 30 + 10).toFixed(2))
      : parseFloat((Math.random() * 40 + 5).toFixed(2));

    return {
      strikePrice: strike,
      expiryDate: "16-Jul-2026", // Simulated upcoming Thursday expiry
      call: {
        symbol: `NIFTY26JUL${strike}CE`,
        ltp: callPremium,
        change: parseFloat(((Math.random() - 0.45) * 5).toFixed(2)),
        oi: Math.floor(Math.random() * 80000 + 10000)
      },
      put: {
        symbol: `NIFTY26JUL${strike}PE`,
        ltp: putPremium,
        change: parseFloat(((Math.random() - 0.55) * 5).toFixed(2)),
        oi: Math.floor(Math.random() * 90000 + 15000)
      }
    };
  });
}

// REST APIs
async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  // Ensure directories exist
  app.use(express.static(path.join(process.cwd(), "public")));

  // 1. Get Live Market Data
  app.get("/api/market-data", (req, res) => {
    res.json({
      indexes: marketIndexes,
      stocks: initialStocks,
      optionsChain: generateOptionsChain(),
      news: [
        { id: 1, title: "Nifty consolidates at 24,300; IT and Automobile stocks shine", source: "MoneyControl", time: "10 mins ago" },
        { id: 2, title: "Reliance Retail looks to expand warehousing footprints with ₹2,000 Cr push", source: "Economic Times", time: "1 hour ago" },
        { id: 3, title: "Hyundai IPO Subscription climbs to 1.8x on final bidding days", source: "LiveMint", time: "2 hours ago" },
        { id: 4, title: "US Fed hints at minor rate cut pause in upcoming policy meeting", source: "Bloomberg", time: "4 hours ago" }
      ]
    });
  });

  // 2. Fetch specific stock historical prices
  app.get("/api/stock/:symbol/history", (req, res) => {
    const { symbol } = req.params;
    const stock = initialStocks.find(s => s.symbol === symbol);
    if (!stock) {
      return res.status(404).json({ error: "Stock not found" });
    }
    const hist = stockHistory[symbol] || [stock.price];
    // return past history array + current dynamic price
    res.json({
      symbol,
      history: [...hist, stock.price]
    });
  });

  // 3. Retrieve User Account State
  app.get("/api/user", (req, res) => {
    // Recalculate portfolio value based on latest market prices
    let positionsVal = 0;
    userState.positions.forEach(pos => {
      const liveStock = initialStocks.find(s => s.symbol === pos.symbol);
      if (liveStock) {
        pos.currentPrice = liveStock.price;
        positionsVal += pos.qty * pos.currentPrice;
      } else if (pos.symbol.includes("CE") || pos.symbol.includes("PE")) {
        // Options contracts keep their seeded price or fluctuate slightly
        positionsVal += pos.qty * pos.currentPrice;
      } else {
        // Mutual Fund / other NAVs
        const mf = mutualFunds.find(f => f.id === pos.symbol);
        if (mf) {
          pos.currentPrice = mf.nav;
          positionsVal += pos.qty * pos.currentPrice;
        }
      }
    });

    userState.portfolioValue = parseFloat(positionsVal.toFixed(2));
    res.json(userState);
  });

  // 4. Place a Trade Order (Paper Trading Execution)
  app.post("/api/order", (req, res) => {
    const { symbol, type, qty, product, category, customPrice } = req.body;
    
    if (!symbol || !type || !qty || qty <= 0) {
      return res.status(400).json({ error: "Invalid order details" });
    }

    let tradePrice = 0;
    if (category === "MUTUAL_FUND") {
      const fund = mutualFunds.find(f => f.id === symbol);
      if (!fund) return res.status(404).json({ error: "Mutual fund not found" });
      tradePrice = fund.nav;
    } else if (category === "IPO") {
      const ipo = ipos.find(i => i.id === symbol);
      if (!ipo) return res.status(404).json({ error: "IPO not found" });
      const priceString = ipo.priceBand.split("-")[1]?.trim().replace("₹", "") || "150";
      tradePrice = parseFloat(priceString);
    } else if (category === "OPTION") {
      // Find Option contract or parse code
      tradePrice = parseFloat(customPrice) || 120;
    } else {
      // Equity
      const stock = initialStocks.find(s => s.symbol === symbol);
      if (!stock) return res.status(404).json({ error: "Stock not found" });
      tradePrice = stock.price;
    }

    const totalCost = tradePrice * qty;

    if (type === "BUY") {
      if (userState.balance < totalCost) {
        return res.status(400).json({ error: `Insufficient virtual balance. Required: ₹${totalCost.toLocaleString('en-IN')}, Available: ₹${userState.balance.toLocaleString('en-IN')}` });
      }
      userState.balance = parseFloat((userState.balance - totalCost).toFixed(2));

      // Update positions
      const existingPos = userState.positions.find(p => p.symbol === symbol && p.product === product);
      if (existingPos) {
        // Recalculate average price
        const totalQty = existingPos.qty + qty;
        const totalCostBasis = (existingPos.avgPrice * existingPos.qty) + totalCost;
        existingPos.qty = totalQty;
        existingPos.avgPrice = parseFloat((totalCostBasis / totalQty).toFixed(2));
      } else {
        userState.positions.push({
          symbol,
          qty,
          avgPrice: tradePrice,
          currentPrice: tradePrice,
          product,
          category
        });
      }

      // Add XP for practicing trades
      userState.xp += 15;
    } else {
      // SELL trade
      const existingPos = userState.positions.find(p => p.symbol === symbol && p.product === product);
      if (!existingPos || existingPos.qty < qty) {
        return res.status(400).json({ error: `No active holdings to sell for ${symbol}. Or insufficient holding qty.` });
      }

      existingPos.qty -= qty;
      userState.balance = parseFloat((userState.balance + totalCost).toFixed(2));

      // Remove position if fully closed
      if (existingPos.qty === 0) {
        userState.positions = userState.positions.filter(p => !(p.symbol === symbol && p.product === product));
      }

      // Add XP
      userState.xp += 20;
    }

    // Check level-up (every 100 XP)
    const newLevel = Math.floor(userState.xp / 100) + 1;
    if (newLevel > userState.level) {
      userState.level = newLevel;
      userState.badges.push(`Level ${newLevel} Specialist`);
    }

    // Append to orders log
    const orderId = "o" + (userState.orders.length + 1);
    const newOrder = {
      id: orderId,
      symbol,
      type,
      product,
      qty,
      price: tradePrice,
      timestamp: new Date().toISOString(),
      category,
      status: "COMPLETED" as const
    };
    userState.orders.unshift(newOrder);

    saveState();
    res.json({ message: "Order executed successfully", order: newOrder, balance: userState.balance });
  });

  // 5. Watchlist Toggle
  app.post("/api/watchlist/toggle", (req, res) => {
    const { symbol } = req.body;
    if (!symbol) return res.status(400).json({ error: "Symbol required" });

    if (userState.watchlist.includes(symbol)) {
      userState.watchlist = userState.watchlist.filter(s => s !== symbol);
    } else {
      userState.watchlist.push(symbol);
    }
    saveState();
    res.json({ watchlist: userState.watchlist });
  });

  // 6. Save Journal Entry
  app.post("/api/journal", (req, res) => {
    const { title, notes, tradesReferenced, emotion } = req.body;
    if (!title || !notes) return res.status(400).json({ error: "Title and notes are required" });

    const newJournal = {
      id: "j" + (userState.journal.length + 1),
      date: new Date().toISOString().split("T")[0],
      title,
      notes,
      tradesReferenced: tradesReferenced || [],
      emotion: emotion || "CALM"
    };

    userState.journal.unshift(newJournal);
    userState.xp += 30; // bonus for journaling!
    saveState();
    res.json({ message: "Trading Journal entry saved!", journal: userState.journal });
  });

  // 7. Complete a Quiz and award XP
  app.post("/api/quiz/complete", (req, res) => {
    const { courseId, score, totalQuestions } = req.body;
    if (!courseId) return res.status(400).json({ error: "courseId required" });

    if (!userState.quizzesCompleted.includes(courseId)) {
      userState.quizzesCompleted.push(courseId);
      // Award substantial XP for completing course quiz
      userState.xp += 100;
      
      // If score is high, award certificate
      const passMark = Math.ceil(totalQuestions * 0.7);
      if (score >= passMark && !userState.certificates.includes(courseId)) {
        userState.certificates.push(courseId);
        userState.badges.push(`${courseId === 'c1' ? 'Market Graduate' : courseId === 'c2' ? 'Chart Expert' : 'Option Master'}`);
      }

      // Check level-up
      const newLevel = Math.floor(userState.xp / 100) + 1;
      if (newLevel > userState.level) {
        userState.level = newLevel;
        userState.badges.push(`Level ${newLevel} Specialist`);
      }

      saveState();
    }

    res.json({
      xp: userState.xp,
      level: userState.level,
      certificates: userState.certificates,
      badges: userState.badges
    });
  });

  // 8. Alerts Creation
  app.post("/api/alerts", (req, res) => {
    const { symbol, targetPrice, condition } = req.body;
    if (!symbol || !targetPrice || !condition) return res.status(400).json({ error: "Missing alert fields" });

    const newAlert = {
      id: "a" + (userState.alerts.length + 1),
      symbol,
      targetPrice: parseFloat(targetPrice),
      condition,
      isActive: true,
      isTriggered: false,
      timestamp: new Date().toISOString()
    };

    userState.alerts.unshift(newAlert);
    saveState();
    res.json({ message: "Price Alert set successfully!", alert: newAlert });
  });

  // 9. Community Social Posting
  app.post("/api/social/post", (req, res) => {
    const { content, tradeShare } = req.body;
    if (!content) return res.status(400).json({ error: "Post content is required" });

    const newPost = {
      id: "post" + (socialPosts.length + 1),
      username: "You (PaperBull)",
      avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80",
      timestamp: new Date().toISOString(),
      content,
      tradeShare,
      likes: 0,
      comments: []
    };

    socialPosts.unshift(newPost);
    userState.xp += 10;
    saveState();
    res.json({ message: "Shared to community successfully", post: newPost });
  });

  app.get("/api/social", (req, res) => {
    res.json({ posts: socialPosts });
  });

  // 10. AI Coach Chat / Trade analysis powered by Google Gemini API
  app.post("/api/ai-coach/analyze", async (req, res) => {
    const { trade, portfolioSummary } = req.body;
    
    let prompt = "";
    if (trade) {
      prompt = `Analyze this virtual trade made in the Indian stock market:
      Action: ${trade.type}
      Asset: ${trade.symbol} (${trade.category})
      Quantity: ${trade.qty}
      Price: ₹${trade.price}
      Demat Mode: ${trade.product}
      
      Please write a highly professional, friendly response as an Indian AI Trading Coach. Explain if this was a smart/risky trade, list key technical levels, outline potential risk management, and provide 2 actionable improvement tips. Translate or write in clean English with common Hinglish stock-terms if suitable. Keep it concise.`;
    } else {
      prompt = `Analyze this overall trading portfolio and risk score:
      ${JSON.stringify(portfolioSummary)}
      
      Suggest high-level diversification advice, calculate standard risk parameters for an Indian retail trader, and share a custom daily improvement tip based on this setup. Keep the tone inspiring and highly professional.`;
    }

    if (ai) {
      try {
        const response = await ai.models.generateContent({
          model: "gemini-3.5-flash",
          contents: prompt,
          config: {
            systemInstruction: "You are 'TradeVerse AI Coach', a smart, motivating, elite stock trading mentor specializing in the Indian Stock Markets (NSE, BSE, F&O, Nifty 50). Avoid dry academic explanations. Focus on risk-to-reward ratios, stop-losses, psychological traps (Greed & Fear), and support/resistance zones. Keep response under 300 words.",
          }
        });
        return res.json({ response: response.text });
      } catch (err) {
        console.error("Gemini API error in analyze route:", err);
      }
    }

    // High fidelity simulated fallback in case API Key is missing
    let fallbackText = "";
    if (trade) {
      fallbackText = `🤖 **TradeVerse AI Coach Analysis:**\n\nYour trade in **${trade.symbol}** for **${trade.qty} shares** at **₹${trade.price}** has been processed under **${trade.product}** product type.\n\n📊 **Risk Assessment: MODERATE**\nReliance Industries and bluechip Indian equities are excellent vehicles for consolidating capital. However, delivering equities requires strong macro-trend analysis. Ensure you have plotted support at ₹2,420 and resistance near ₹2,510.\n\n💡 **Coaching Tips:**\n1. **Stop Loss (SL):** Always pre-define your psychological exit. For this trade, a stop-loss around ₹2,415 helps preserve ₹10 Lakh paper capital.\n2. **Trading Journal:** Excellent work tagging this trade. Compare this entry with daily charts to confirm if volume was above average.`;
    } else {
      fallbackText = `🤖 **TradeVerse AI Coach Portfolio Analysis:**\n\nYour total portfolio balance represents **₹${(userState.balance + userState.portfolioValue).toLocaleString('en-IN')}**. You are currently concentrated in bluechip equities. \n\n📉 **Sharpe Ratio Assessment:** ~1.85 (Strong risk-adjusted returns)\n\n📈 **Diversification Advice:** \nConsider expanding into Option PE/CE hedging or indexing (Nifty 50 index ETFs) to reduce reliance on individual sectors like Energy. Keep practicing with virtual contracts before using premium capital!`;
    }

    res.json({ response: fallbackText });
  });

  app.post("/api/ai-coach/chat", async (req, res) => {
    const { message, chatHistory } = req.body;
    if (!message) return res.status(400).json({ error: "Message is required" });

    let systemPrompt = "You are 'TradeVerse AI Coach', an expert, helpful AI stock market trading mentor for Indian retail traders. You understand NSE, BSE, Nifty, Bank Nifty, candlestick patterns, support/resistance, option chains, and common trading rules. Answer questions precisely, explain concepts with simple real-world analogies, and offer daily improvement tips.";

    if (ai) {
      try {
        const response = await ai.models.generateContent({
          model: "gemini-3.5-flash",
          contents: message,
          config: {
            systemInstruction: systemPrompt,
          }
        });
        return res.json({ response: response.text });
      } catch (err) {
        console.error("Gemini API error in chat route:", err);
      }
    }

    // Local smart simulator matching key technical keywords
    const lowerMsg = message.toLowerCase();
    let reply = "I am your TradeVerse AI Coach! Ask me about candlesticks, Nifty options, support levels, or the difference between Intraday and Delivery.";
    
    if (lowerMsg.includes("candlestick") || lowerMsg.includes("pattern") || lowerMsg.includes("hammer") || lowerMsg.includes("doji")) {
      reply = `🕯️ **Candlestick Patterns Guide:**\n\nCandlesticks represent price battles over time. \n- **Hammer:** A bullish reversal indicator forming at bottoms with a long lower tail. It signals that buyers rejected lower rates.\n- **Doji:** Indecision candle where Open and Close are virtually equal.\n- **Bullish Engulfing:** A large green candle completely swallows the previous red candle, showing extreme buyers' control.`;
    } else if (lowerMsg.includes("option") || lowerMsg.includes("f&o") || lowerMsg.includes("ce") || lowerMsg.includes("pe")) {
      reply = `📈 **F&O & Options Trading Concept:**\n\nIn India, Call Options are called **CE (Call European)** and Puts are **PE (Put European)**.\n- Buying a **CE** grants you the right to buy the asset, profiting when the market swings **upward**.\n- Buying a **PE** profits when the market moves **downward**.\n\n*Warning:* F&O is high-leverage. More than 90% of retail option buyers lose money due to Theta (Time Decay). Ensure you practice thoroughly on this Paper simulator!`;
    } else if (lowerMsg.includes("sip") || lowerMsg.includes("mutual fund")) {
      reply = `💰 **SIP & Mutual Funds:**\n\nA **Systematic Investment Plan (SIP)** allows you to compound wealth automatically by investing fixed amounts monthly in mutual funds. It averages out market volatility (Rupee Cost Averaging). In our simulator, you can try starting a mock SIP to see how interest adds up over 5 years!`;
    } else if (lowerMsg.includes("nifty") || lowerMsg.includes("sensex")) {
      reply = `📊 **Index Information:**\n\n- **Nifty 50** represents the weighted average of the top 50 bluechip companies listed on the National Stock Exchange (NSE). It's the primary benchmark for the Indian economy.\n- **SENSEX** represents the top 30 established companies on the Bombay Stock Exchange (BSE).`;
    }

    res.json({ response: reply });
  });

  // Fetch pre-configured Courses
  app.get("/api/courses", (req, res) => {
    res.json({ courses, mutualFunds, ipos });
  });

  // Weekly simulated Leaderboards
  app.get("/api/leaderboard", (req, res) => {
    const defaultLeaderboard = [
      { rank: 1, username: "Rohan_AlphaTrdr", portfolioValue: 1245000, pnlPercent: 24.5 },
      { rank: 2, username: "Suresh_ValueInv", portfolioValue: 1180200, pnlPercent: 18.02 },
      { rank: 3, username: "Neha_Invests", portfolioValue: 1152000, pnlPercent: 15.2 },
      { rank: 4, username: "Aniket_Bull", portfolioValue: 1110500, pnlPercent: 11.05 }
    ];

    // Calculate current user stats
    const currentUserPnl = parseFloat((((userState.balance + userState.portfolioValue) - 1000000) / 1000000 * 100).toFixed(2));
    const currentUserValue = userState.balance + userState.portfolioValue;

    // Insert user into correct leaderboard rank
    const fullLeaderboard = [
      ...defaultLeaderboard,
      { rank: 5, username: "You (PaperBull)", portfolioValue: currentUserValue, pnlPercent: currentUserPnl, isCurrentUser: true }
    ].sort((a, b) => b.portfolioValue - a.portfolioValue);

    // Re-rank
    fullLeaderboard.forEach((item, index) => {
      item.rank = index + 1;
    });

    res.json({ leaderboard: fullLeaderboard });
  });

  // Voice Assistant speech-text query proxy
  app.post("/api/voice-assistant", async (req, res) => {
    const { query } = req.body;
    if (!query) return res.status(400).json({ error: "Query is required" });

    const prompt = `Give a short 1-2 sentence stock quote/market update voice answer for: '${query}'. Keep it crisp, friendly and professional.`;
    
    if (ai) {
      try {
        const response = await ai.models.generateContent({
          model: "gemini-3.5-flash",
          contents: prompt,
        });
        return res.json({ answer: response.text });
      } catch (err) {
        console.error("Gemini voice assistant error:", err);
      }
    }

    // Fast static fallback
    let fallback = "Current Nifty index is stable around 24,320. Reliance Industries is ticking higher at 2480.";
    if (query.toLowerCase().includes("tcs")) fallback = "TCS is currently trading at approximately 3820, down minorly today.";
    else if (query.toLowerCase().includes("reliance")) fallback = "Reliance is exhibiting bullish momentum, hovering around 2480.";

    res.json({ answer: fallback });
  });

  // Serve static assets in production, otherwise Vite handles it
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Express server fully operational on port ${PORT}`);
  });
}

startServer();
