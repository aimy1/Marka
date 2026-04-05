class WorkspaceItem {
  final String path;
  final String name;
  final bool isDirectory;

  WorkspaceItem({
    required this.path,
    required this.name,
    this.isDirectory = false,
  });
}
