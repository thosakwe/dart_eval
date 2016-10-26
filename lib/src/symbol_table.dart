class SymbolTable {
  SymbolTable _child = null;
  SymbolTable _parent;
  SymbolTable get child => _child;
  final bool debug;
  SymbolTable get parent => _parent;
  final Map<Symbol, dynamic> symbols = {};

  SymbolTable({this.debug: false});

  SymbolTable get bottom {
    SymbolTable bottom = this;

    // Navigate to bottom
    while (bottom._child != null) bottom = bottom._child;

    return bottom;
  }

  operator [](Symbol sym) => get(sym);
  operator []=(Symbol sym, value) => set(sym, value);

  void enter() {
    final table = bottom;
    table._child = new SymbolTable().._parent = table;
  }

  void exit() {
    bottom._parent?._child = null;
  }

  get(Symbol sym) {
    printDebug('Searching for $sym');

    // Backtrack to top
    searchTable(SymbolTable table) {
      printDebug('containsKey: ${table.symbols.containsKey(sym)}');
      if (table.symbols.containsKey(sym))
        return table.symbols[sym];
      else if (table.parent != null) {
        printDebug('$sym not found, heading up one level...');
        return searchTable(table.parent);
      } else {
        printDebug("$sym does not exist within this symbol table.");
        return null;
      }
    }

    final result = searchTable(bottom);
    printDebug('Search result: $result');
    return result;
  }

  printDebug(Object object) {
    if (debug) print(object);
  }

  set(Symbol sym, value) => bottom.symbols[sym] = value;
}
