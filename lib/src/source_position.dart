/// Position in the source code.
class SourcePosition {
  const SourcePosition(this.offset, this.line, this.column);

  final int offset;

  final int line;

  final int column;

  @override
  String toString() {
    return '$line:$column';
  }
}
