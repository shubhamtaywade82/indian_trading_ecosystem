module Market
  class DepthSimulator
    def self.generate(runtime, ltp, spread)
      # Synthetic depth generation when L2 data is unavailable
      {
        bids: [
          { price: ltp - spread, quantity: 1000 },
          { price: ltp - spread * 2, quantity: 2500 },
          { price: ltp - spread * 3, quantity: 5000 }
        ],
        asks: [
          { price: ltp + spread, quantity: 1000 },
          { price: ltp + spread * 2, quantity: 2500 },
          { price: ltp + spread * 3, quantity: 5000 }
        ]
      }
    end
  end
end
