extension FetchableRecord where Self: TableRecord {
    
    // MARK: Fetching All
    
    /// A cursor over all records fetched from the database.
    ///
    ///     // SELECT * FROM player
    ///     let players = try Player.fetchCursor(db) // Cursor of Player
    ///     while let player = try players.next() {  // Player
    ///         ...
    ///     }
    ///
    /// Records are iterated in the natural ordering of the table.
    ///
    /// If the database is modified during the cursor iteration, the remaining
    /// elements are undefined.
    ///
    /// The cursor must be iterated in a protected dispatch queue.
    ///
    /// The selection defaults to all columns. This default can be changed for
    /// all requests by the `TableRecord.databaseSelection` property, or
    /// for individual requests with the `TableRecord.select` method.
    ///
    /// - parameter db: A database connection.
    /// - returns: A cursor over fetched records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchCursor(_ db: Database) throws -> RecordCursor<Self> {
        try all().fetchCursor(db)
    }
    
    /// An array of all records fetched from the database.
    ///
    ///     // SELECT * FROM player
    ///     let players = try Player.fetchAll(db) // [Player]
    ///
    /// The selection defaults to all columns. This default can be changed for
    /// all requests by the `TableRecord.databaseSelection` property, or
    /// for individual requests with the `TableRecord.select` method.
    ///
    /// - parameter db: A database connection.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchAll(_ db: Database) throws -> [Self] {
        try all().fetchAll(db)
    }
    
    /// The first found record.
    ///
    ///     // SELECT * FROM player
    ///     let player = try Player.fetchOne(db) // Player?
    ///
    /// The selection defaults to all columns. This default can be changed for
    /// all requests by the `TableRecord.databaseSelection` property, or
    /// for individual requests with the `TableRecord.select` method.
    ///
    /// - parameter db: A database connection.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchOne(_ db: Database) throws -> Self? {
        try all().fetchOne(db)
    }
}

extension FetchableRecord where Self: TableRecord & Hashable {
    /// A set of all records fetched from the database.
    ///
    ///     // SELECT * FROM player
    ///     let players = try Player.fetchSet(db) // Set<Player>
    ///
    /// The selection defaults to all columns. This default can be changed for
    /// all requests by the `TableRecord.databaseSelection` property, or
    /// for individual requests with the `TableRecord.select` method.
    ///
    /// - parameter db: A database connection.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchSet(_ db: Database) throws -> Set<Self> {
        try all().fetchSet(db)
    }
}

extension FetchableRecord where Self: TableRecord {
    
    // MARK: Fetching by Single-Column Primary Key
    
    /// Returns a cursor over records, given their primary keys.
    ///
    ///     let players = try Player.fetchCursor(db, keys: [1, 2, 3]) // Cursor of Player
    ///     while let player = try players.next() { // Player
    ///         ...
    ///     }
    ///
    /// Records are iterated in unspecified order.
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - keys: A sequence of primary keys.
    /// - returns: A cursor over fetched records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchCursor<Sequence>(_ db: Database, keys: Sequence)
        throws -> RecordCursor<Self>
        where Sequence: Swift.Sequence, Sequence.Element: DatabaseValueConvertible
    {
        try filter(keys: keys).fetchCursor(db)
    }
    
    /// Returns an array of records, given their primary keys.
    ///
    ///     let players = try Player.fetchAll(db, keys: [1, 2, 3]) // [Player]
    ///
    /// The order of records in the returned array is undefined.
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - keys: A sequence of primary keys.
    /// - returns: An array of records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchAll<Sequence>(_ db: Database, keys: Sequence)
        throws -> [Self]
        where Sequence: Swift.Sequence, Sequence.Element: DatabaseValueConvertible
    {
        let keys = Array(keys)
        if keys.isEmpty {
            // Avoid hitting the database
            return []
        }
        return try filter(keys: keys).fetchAll(db)
    }
    
    /// Returns a single record given its primary key.
    ///
    ///     let player = try Player.fetchOne(db, key: 123) // Player?
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - key: A primary key value.
    /// - returns: An optional record.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchOne<PrimaryKeyType>(_ db: Database, key: PrimaryKeyType?)
        throws -> Self?
        where PrimaryKeyType: DatabaseValueConvertible
    {
        guard let key = key else {
            // Avoid hitting the database
            return nil
        }
        return try filter(key: key).fetchOne(db)
    }
}

extension FetchableRecord where Self: TableRecord & Hashable {
    /// Returns a set of records, given their primary keys.
    ///
    ///     let players = try Player.fetchSet(db, keys: [1, 2, 3]) // Set<Player>
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - keys: A sequence of primary keys.
    /// - returns: A set of records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchSet<Sequence>(_ db: Database, keys: Sequence)
        throws -> Set<Self>
        where Sequence: Swift.Sequence, Sequence.Element: DatabaseValueConvertible
    {
        let keys = Array(keys)
        if keys.isEmpty {
            // Avoid hitting the database
            return []
        }
        return try filter(keys: keys).fetchSet(db)
    }
}

extension FetchableRecord where Self: TableRecord {
    
    // MARK: Fetching by Key
    
    /// Returns a cursor over records identified by the provided unique keys
    /// (primary key or any key with a unique index on it).
    ///
    ///     // Cursor of Player
    ///     let players = try Player.fetchCursor(db, keys: [
    ///         ["email": "a@example.com"],
    ///         ["email": "b@example.com"]])
    ///     while let player = try players.next() { // Player
    ///         ...
    ///     }
    ///
    /// Records are iterated in unspecified order.
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - keys: An array of key dictionaries.
    /// - returns: A cursor over fetched records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchCursor(_ db: Database, keys: [[String: DatabaseValueConvertible?]])
        throws -> RecordCursor<Self>
    {
        try filter(keys: keys).fetchCursor(db)
    }
    
    /// Returns an array of records identified by the provided unique keys
    /// (primary key or any key with a unique index on it).
    ///
    ///     // [Player]
    ///     let players = try Player.fetchAll(db, keys: [
    ///         ["email": "a@example.com"],
    ///         ["email": "b@example.com"]])
    ///
    /// The order of records in the returned array is undefined.
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - keys: An array of key dictionaries.
    /// - returns: An array of records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchAll(_ db: Database, keys: [[String: DatabaseValueConvertible?]]) throws -> [Self] {
        if keys.isEmpty {
            // Avoid hitting the database
            return []
        }
        return try filter(keys: keys).fetchAll(db)
    }
    
    /// Returns a single record identified by a unique key (the primary key or
    /// any key with a unique index on it).
    ///
    ///     let player = try Player.fetchOne(db, key: ["name": Arthur"]) // Player?
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - key: A dictionary of values.
    /// - returns: An optional record.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchOne(_ db: Database, key: [String: DatabaseValueConvertible?]?) throws -> Self? {
        guard let key = key else {
            // Avoid hitting the database
            return nil
        }
        return try filter(key: key).fetchOne(db)
    }
}

extension FetchableRecord where Self: TableRecord & Hashable {
    /// Returns a set of records identified by the provided unique keys
    /// (primary key or any key with a unique index on it).
    ///
    ///     // Set<Player>
    ///     let players = try Player.fetchSet(db, keys: [
    ///         ["email": "a@example.com"],
    ///         ["email": "b@example.com"]])
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - keys: An array of key dictionaries.
    /// - returns: A set of records.
    /// - throws: A DatabaseError is thrown whenever an SQLite error occurs.
    public static func fetchSet(_ db: Database, keys: [[String: DatabaseValueConvertible?]]) throws -> Set<Self> {
        if keys.isEmpty {
            // Avoid hitting the database
            return []
        }
        return try filter(keys: keys).fetchSet(db)
    }
}
