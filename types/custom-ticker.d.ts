export interface CustomTickerInstance {
  destroy(): void
}

export interface CustomTicker {
  (fps: number, fn: () => void, performance?: { now(): DOMHighResTimeStamp }): CustomTickerInstance
}
