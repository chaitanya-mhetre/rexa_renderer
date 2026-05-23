class SduiAction {
  final String actionType;
  final Map<String, dynamic> props;

  const SduiAction({required this.actionType, required this.props});

  factory SduiAction.fromJson(Map<String, dynamic> json) {
    final t = json['actionType'];
    if (t is! String) {
      throw ArgumentError('SduiAction.fromJson: missing actionType');
    }
    return SduiAction(
      actionType: t,
      props: Map<String, dynamic>.from(json)..remove('actionType'),
    );
  }

  Map<String, dynamic> toJson() => {'actionType': actionType, ...props};

  @override
  String toString() => 'SduiAction($actionType, $props)';
}
