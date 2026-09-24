export const COLORS = {
  background: '#0A0A0F',
  surface: '#12121A',
  surfaceElevated: '#1A1A24',
  border: '#2A2A3A',
  borderLight: '#3A3A4A',
  textPrimary: '#F5F5F5',
  textSecondary: '#A0A0B0',
  textMuted: '#6A6A7A',
  textOnNeon: '#0A0A0F',
  neonPink: '#FF006E',
  neonAmber: '#FFBE0B',
  neonViolet: '#8338EC',
  neonMint: '#06D6A0',
  neonCyan: '#118AB2',
  neonRed: '#FF6B6B',
  neonTeal: '#4ECDC4',
  neonGold: '#FFD166',
  neonPurple: '#C44DFF',
  neonEmerald: '#00D4AA',
  error: '#FF4444',
  success: '#00C853',
  warning: '#FFB300',
};

export const SPACING = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
};

export const RADIUS = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 9999,
};

export const TYPOGRAPHY = {
  fontFamily: {
    heading: 'SpaceGrotesk_700Bold',
    headingMedium: 'SpaceGrotesk_600SemiBold',
    body: 'System',
    bodyMedium: 'System',
    mono: 'SpaceMono_400Regular',
  },
  fontSize: {
    xs: 12,
    sm: 14,
    md: 16,
    lg: 20,
    xl: 28,
    xxl: 36,
    xxxl: 48,
    display: 64,
  },
  lineHeight: {
    tight: 1.1,
    normal: 1.4,
    relaxed: 1.6,
  },
};

export const SHADOWS = {
  neon: (color: string) => ({
    shadowColor: color,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.4,
    shadowRadius: 16,
    elevation: 8,
  }),
  card: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 6,
  },
};

export const TOUCH_TARGET = {
  minimum: 48,
  comfortable: 56,
  large: 64,
};

export const ANIMATION = {
  fast: 200,
  normal: 300,
  slow: 500,
  flip: 600,
  stagger: 80,
};

export const NEON_PALETTE = [
  '#FF006E',
  '#FFBE0B',
  '#8338EC',
  '#06D6A0',
  '#118AB2',
  '#FF6B6B',
  '#4ECDC4',
  '#FFD166',
  '#C44DFF',
  '#00D4AA',
];

export const CARD = {
  width: 340,
  height: 480,
  maxWidth: 360,
  maxHeight: 500,
  borderRadius: 24,
};

export const TIMER_RING = {
  size: 280,
  strokeWidth: 12,
  maxSize: 320,
};

export const BUILTIN_CATEGORIES = [
  {
    id: 'movies',
    name: 'Movies',
    neonColor: '#FF006E',
    hintPrefix: "It's a film...",
    words: [
      'Inception', 'The Matrix', 'Parasite', 'Interstellar', 'Pulp Fiction',
      'The Godfather', 'Fight Club', 'The Dark Knight', 'Forrest Gump', 'Titanic',
      'Avatar', 'Gladiator', 'The Shawshank Redemption', 'Goodfellas', 'The Silence of the Lambs',
      'Se7en', 'The Usual Suspects', 'Saving Private Ryan', 'The Green Mile', 'Jurassic Park',
      'Back to the Future', 'The Terminator', 'Alien', 'Blade Runner', 'The Prestige',
    ],
    isCustom: false,
  },
  {
    id: 'food',
    name: 'Food',
    neonColor: '#FFBE0B',
    hintPrefix: "It's something you eat...",
    words: [
      'Sushi', 'Tacos', 'Ramen', 'Croissant', 'Pizza',
      'Burger', 'Pad Thai', 'Dim Sum', 'Paella', 'Tiramisu',
      'Curry', 'Bibimbap', 'Pho', 'Empanadas', 'Gelato',
      'Waffles', 'Dumplings', 'Ceviche', 'Ratatouille', 'Churros',
      'Baklava', 'Gnocchi', 'Shawarma', 'Poutine', 'Cheesecake',
    ],
    isCustom: false,
  },
  {
    id: 'celebrities',
    name: 'Celebrities',
    neonColor: '#8338EC',
    hintPrefix: "They're famous for...",
    words: [
      'Taylor Swift', 'Keanu Reeves', 'Beyoncé', 'Leonardo DiCaprio', 'Tom Hanks',
      'Meryl Streep', 'Brad Pitt', 'Jennifer Lawrence', 'Robert Downey Jr.', 'Scarlett Johansson',
      'Dwayne Johnson', 'Emma Watson', 'Chris Evans', 'Zendaya', 'Ryan Reynolds',
      'Margot Robbie', 'Michael B. Jordan', 'Florence Pugh', 'Timothée Chalamet', 'Anya Taylor-Joy',
    ],
    isCustom: false,
  },
  {
    id: 'animals',
    name: 'Animals',
    neonColor: '#06D6A0',
    hintPrefix: "It's a creature...",
    words: [
      'Penguin', 'Octopus', 'Red Panda', 'Axolotl', 'Narwhal',
      'Sloth', 'Quokka', 'Fennec Fox', 'Mantis Shrimp', 'Capybara',
      'Platypus', 'Snow Leopard', 'Blue Whale', 'Hummingbird', 'Chameleon',
      'Arctic Fox', 'Sea Turtle', 'Elephant', 'Tiger', 'Dolphin',
    ],
    isCustom: false,
  },
  {
    id: 'places',
    name: 'Places',
    neonColor: '#118AB2',
    hintPrefix: "It's a location...",
    words: [
      'Tokyo', 'Paris', 'Machu Picchu', 'Santorini', 'New York City',
      'Dubai', 'Rome', 'Bali', 'Iceland', 'Venice',
      'Barcelona', 'Kyoto', 'Marrakech', 'Rio de Janeiro', 'Sydney',
      'Prague', 'Cape Town', 'Banff', 'Petra', 'Maldives',
    ],
    isCustom: false,
  },
  {
    id: 'books',
    name: 'Books',
    neonColor: '#FF6B6B',
    hintPrefix: "It's a book...",
    words: [
      '1984', 'To Kill a Mockingbird', 'The Great Gatsby', 'Harry Potter', 'The Hobbit',
      'Pride and Prejudice', 'The Catcher in the Rye', 'Lord of the Rings', 'Dune', 'Sapiens',
      'The Alchemist', 'Atomic Habits', 'Educated', 'Becoming', 'The Subtle Art',
      'Thinking Fast and Slow', 'The Power of Now', 'Outliers', 'Grit', 'Mindset',
    ],
    isCustom: false,
  },
  {
    id: 'brands',
    name: 'Brands',
    neonColor: '#4ECDC4',
    hintPrefix: "It's a brand...",
    words: [
      'Apple', 'Nike', 'Tesla', 'Coca-Cola', 'Google',
      'Amazon', 'Microsoft', 'Disney', 'Netflix', 'Spotify',
      'Adidas', 'Samsung', 'Sony', 'BMW', 'Mercedes',
      'Louis Vuitton', 'Gucci', 'Rolex', 'Ferrari', 'Lego',
    ],
    isCustom: false,
  },
  {
    id: 'sports',
    name: 'Sports',
    neonColor: '#FFD166',
    hintPrefix: "It's a sport...",
    words: [
      'Soccer', 'Basketball', 'Tennis', 'Swimming', 'Golf',
      'Boxing', 'Skiing', 'Surfing', 'Climbing', 'Cycling',
      'Running', 'Yoga', 'Football', 'Baseball', 'Hockey',
      'Volleyball', 'Rugby', 'Cricket', 'Skateboarding', 'Gymnastics',
    ],
    isCustom: false,
  },
  {
    id: 'music',
    name: 'Music',
    neonColor: '#C44DFF',
    hintPrefix: "It's music-related...",
    words: [
      'Guitar', 'Piano', 'Drums', 'Violin', 'Saxophone',
      'Concert', 'Festival', 'Album', 'Symphony', 'Jazz',
      'Rock', 'Pop', 'Hip Hop', 'Classical', 'Electronic',
      'Opera', 'Broadway', 'Karaoke', 'DJ', 'Vinyl',
    ],
    isCustom: false,
  },
  {
    id: 'historical',
    name: 'Historical Figures',
    neonColor: '#00D4AA',
    hintPrefix: "They made history...",
    words: [
      'Einstein', 'Cleopatra', 'Da Vinci', 'Napoleon', 'Shakespeare',
      'Newton', 'Galileo', 'Marie Curie', 'Lincoln', 'Gandhi',
      'Mandela', 'Churchill', 'Tesla', 'Darwin', 'Mozart',
      'Michelangelo', 'Columbus', 'Marco Polo', 'Joan of Arc', 'Alexander',
    ],
    isCustom: false,
  },
];

export type Category = typeof BUILTIN_CATEGORIES[number];