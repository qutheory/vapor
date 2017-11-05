extension Promise {
    /// Flattens a future's completions and failures into this promise with the same expectations
    public func flatten(_ future: Future<T>) {
        future.then(callback: self.complete).catch(callback: self.fail)
    }
}
