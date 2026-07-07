export interface Stock {
  symbol: string;
  name: string;
  price: number;
  prevClose: number;
  change: number;
  changePercent: number;
  high: number;
  low: number;
  volume: number;
  sector: string;
  history: number[]; // Daily close historical price for chart
}

export interface MarketIndex {
  name: string;
  price: number;
  change: number;
  changePercent: number;
  history: number[];
}

export type OrderType = 'BUY' | 'SELL';
export type OrderProduct = 'INTRADAY' | 'DELIVERY';

export interface Order {
  id: string;
  symbol: string;
  type: OrderType;
  product: OrderProduct;
  qty: number;
  price: number;
  timestamp: string;
  category: 'EQUITY' | 'OPTION' | 'MUTUAL_FUND' | 'IPO';
  status: 'COMPLETED' | 'CANCELLED' | 'PENDING';
}

export interface Position {
  symbol: string;
  qty: number;
  avgPrice: number;
  currentPrice: number;
  product: OrderProduct;
  category: 'EQUITY' | 'OPTION' | 'MUTUAL_FUND';
}

export interface OptionContract {
  strikePrice: number;
  expiryDate: string;
  call: {
    symbol: string;
    ltp: number;
    change: number;
    oi: number;
  };
  put: {
    symbol: string;
    ltp: number;
    change: number;
    oi: number;
  };
}

export interface MutualFund {
  id: string;
  name: string;
  nav: number;
  category: 'EQUITY' | 'DEBT' | 'HYBRID' | 'INDEX';
  return3Y: number;
  risk: 'LOW' | 'MODERATE' | 'HIGH';
  minSip: number;
}

export interface Ipo {
  id: string;
  companyName: string;
  priceBand: string;
  lotSize: number;
  issueSize: string;
  openDate: string;
  closeDate: string;
  status: 'OPEN' | 'CLOSED' | 'LISTED';
}

export interface JournalEntry {
  id: string;
  date: string;
  title: string;
  notes: string;
  tradesReferenced: string[]; // Order IDs
  emotion: 'CALM' | 'GREEDY' | 'FEARFUL' | 'EXCITED' | 'REGRETFUL';
}

export interface QuizQuestion {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
}

export interface Course {
  id: string;
  title: string;
  description: string;
  difficulty: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';
  lessons: {
    id: string;
    title: string;
    content: string;
  }[];
  quizzes: QuizQuestion[];
}

export interface LeaderboardUser {
  rank: number;
  username: string;
  portfolioValue: number;
  pnlPercent: number;
  isCurrentUser?: boolean;
}

export interface SocialPost {
  id: string;
  username: string;
  avatarUrl: string;
  timestamp: string;
  content: string;
  tradeShare?: {
    symbol: string;
    type: OrderType;
    pnl?: number;
    price: number;
  };
  likes: number;
  comments: {
    id: string;
    username: string;
    content: string;
    timestamp: string;
  }[];
}

export interface PriceAlert {
  id: string;
  symbol: string;
  targetPrice: number;
  condition: 'ABOVE' | 'BELOW';
  isActive: boolean;
  isTriggered: boolean;
  timestamp: string;
}

export interface UserState {
  balance: number;
  portfolioValue: number;
  positions: Position[];
  orders: Order[];
  watchlist: string[]; // Stock symbols
  xp: number;
  level: number;
  badges: string[]; // List of badge names
  quizzesCompleted: string[]; // Question IDs or course IDs
  certificates: string[]; // Course IDs
  alerts: PriceAlert[];
  journal: JournalEntry[];
  following: string[]; // Usernames
}
