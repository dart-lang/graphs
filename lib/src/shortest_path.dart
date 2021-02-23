// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/// Returns the shortest path from [start] to [target] given the directed
/// edges of a graph provided by [edges].
///
/// If [start] `==` [target], an empty [List] is returned and [edges] is never
/// called.
///
/// [start], [target] and all values returned by [edges] must not be `null`.
/// If asserts are enabled, an [AssertionError] is raised if these conditions
/// are not met. If asserts are not enabled, violations result in undefined
/// behavior.
///
/// If [equals] is provided, it is used to compare nodes in the graph. If
/// [equals] is omitted, the node's own [Object.==] is used instead.
///
/// Similarly, if [hashCode] is provided, it is used to produce a hash value
/// for nodes to efficiently calculate the return value. If it is omitted, the
/// key's own [Object.hashCode] is used.
///
/// If you supply one of [equals] or [hashCode], you should generally also to
/// supply the other.
Iterable<T> shortestPath<T>(
  T start,
  T target,
  Iterable<T> Function(T) edges, {
  bool Function(T, T) equals,
  int Function(T) hashCode,
}) =>
    _shortestPaths<T>(
      start,
      edges,
      target: target,
      equals: equals,
      hashCode: hashCode,
    )[target];

/// Returns a [Map] of the shortest paths from [start] to all of the nodes in
/// the directed graph defined by [edges].
///
/// All return values will contain the key [start] with an empty [List] value.
///
/// [start] and all values returned by [edges] must not be `null`.
/// If asserts are enabled, an [AssertionError] is raised if these conditions
/// are not met. If asserts are not enabled, violations result in undefined
/// behavior.
///
/// If [equals] is provided, it is used to compare nodes in the graph. If
/// [equals] is omitted, the node's own [Object.==] is used instead.
///
/// Similarly, if [hashCode] is provided, it is used to produce a hash value
/// for nodes to efficiently calculate the return value. If it is omitted, the
/// key's own [Object.hashCode] is used.
///
/// If you supply one of [equals] or [hashCode], you should generally also to
/// supply the other.
Map<T, Iterable<T>> shortestPaths<T>(
  T start,
  Iterable<T> Function(T) edges, {
  bool Function(T, T) equals,
  int Function(T) hashCode,
}) =>
    _shortestPaths<T>(
      start,
      edges,
      equals: equals,
      hashCode: hashCode,
    );

Map<T, Iterable<T>> _shortestPaths<T>(
  T start,
  Iterable<T> Function(T) edges, {
  T target,
  bool Function(T, T) equals,
  int Function(T) hashCode,
}) {
  assert(start != null, '`start` cannot be null');
  assert(edges != null, '`edges` cannot be null');

  final distances = HashMap<T, _Tail<T>>(equals: equals, hashCode: hashCode);
  distances[start] = _Tail<T>();

  equals ??= _defaultEquals;
  if (equals(start, target)) {
    return distances;
  }

  final toVisit = ListQueue<T>()..add(start);

  while (toVisit.isNotEmpty) {
    final current = toVisit.removeFirst();
    final currentPath = distances[current];

    for (var edge in edges(current)) {
      assert(edge != null, '`edges` cannot return null values.');
      final existingPath = distances[edge];

      if (existingPath == null) {
        distances[edge] = currentPath.append(edge);
        if (equals(edge, target)) {
          return distances;
        }
        toVisit.add(edge);
      }
    }
  }

  return distances;
}

bool _defaultEquals(Object a, Object b) => a == b;

/// An immutable iterable that can efficiently return a copy with a value
/// appended.
///
/// This implementation has an efficient [length] property.
///
/// Note that grabbing an [iterator] for the first time is O(n) in time and
/// space because it copies all the values to a new list and uses that
/// iterator in order to avoid stack overflows for large paths. This copy is
/// cached for subsequent calls.
class _Tail<T> extends Iterable<T> {
  final T /*?*/ tail;
  final _Tail<T> /*?*/ head;
  @override
  final int length;
  _Tail()
      : tail = null,
        head = null,
        length = 0;
  _Tail._(this.tail, this.head, this.length);
  _Tail<T> append(T value) => _Tail._(value, this, length + 1);

  Iterator<T> /*?*/ _iterator;

  @override
  Iterator<T> get iterator {
    if (_iterator == null) {
      var /*_Tail<T>?*/ next = this;
      var values = List<T>.generate(length, (_) {
        var val = next.tail;
        next = next.head;
        return val;
      });
      _iterator = values.reversed.iterator;
    }
    return _iterator;
  }
}
