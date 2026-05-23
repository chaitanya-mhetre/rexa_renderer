import 'dart:async';

abstract class SduiLifecycleEvent {}

class SduiFetchStartEvent extends SduiLifecycleEvent {}

class SduiFetchDoneEvent extends SduiLifecycleEvent {}

class SduiFetchErrorEvent extends SduiLifecycleEvent {
  final Object error;
  SduiFetchErrorEvent(this.error);
}

class SduiController {
  Future<void> Function()? _refreshFn;
  Future<void> Function()? _clearAndRefreshFn;
  bool _attached = false;
  final _events = StreamController<SduiLifecycleEvent>.broadcast();

  Stream<SduiLifecycleEvent> get events => _events.stream;
  bool _isFetching = false;
  bool get isFetching => _isFetching;

  void attach(
    Future<void> Function() refreshFn,
    Future<void> Function() clearAndRefreshFn,
  ) {
    if (_attached) {
      throw StateError(
        'SduiController already attached. Create a new instance per SduiScreen.',
      );
    }
    _refreshFn = refreshFn;
    _clearAndRefreshFn = clearAndRefreshFn;
    _attached = true;
  }

  void detach() {
    _attached = false;
    _refreshFn = null;
    _clearAndRefreshFn = null;
  }

  Future<void> refresh() async {
    if (_refreshFn == null) return;
    await _refreshFn!();
  }

  Future<void> clearCacheAndRefresh() async {
    if (_clearAndRefreshFn == null) return;
    await _clearAndRefreshFn!();
  }

  void notifyFetchStart() {
    _isFetching = true;
    _events.add(SduiFetchStartEvent());
  }

  void notifyFetchDone() {
    _isFetching = false;
    _events.add(SduiFetchDoneEvent());
  }

  void notifyFetchError(Object e) {
    _isFetching = false;
    _events.add(SduiFetchErrorEvent(e));
  }

  void dispose() {
    _events.close();
  }
}
