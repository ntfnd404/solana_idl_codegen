/// Callback used by validation rules to report an ordered semantic issue.
typedef ValidationIssue =
    void Function(String code, String message, String path);
