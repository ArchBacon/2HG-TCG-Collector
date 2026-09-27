// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CollectionSummary {

 CollectionSummaryTotal get total; Map<String, CollectionSummaryTcg> get tcgs;
/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionSummaryCopyWith<CollectionSummary> get copyWith => _$CollectionSummaryCopyWithImpl<CollectionSummary>(this as CollectionSummary, _$identity);

  /// Serializes this CollectionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CollectionSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionSummary&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.tcgs, _this.tcgs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CollectionSummary;
  return Object.hash(runtimeType,_this.total,const DeepCollectionEquality().hash(_this.tcgs));
}

@override
String toString() {
  final _this = this as CollectionSummary;
  return 'CollectionSummary(total: ${_this.total}, tcgs: ${_this.tcgs})';
}


}

/// @nodoc
abstract mixin class $CollectionSummaryCopyWith<$Res>  {
  factory $CollectionSummaryCopyWith(CollectionSummary value, $Res Function(CollectionSummary) _then) = _$CollectionSummaryCopyWithImpl;
@useResult
$Res call({
 CollectionSummaryTotal total, Map<String, CollectionSummaryTcg> tcgs
});


$CollectionSummaryTotalCopyWith<$Res> get total;

}
/// @nodoc
class _$CollectionSummaryCopyWithImpl<$Res>
    implements $CollectionSummaryCopyWith<$Res> {
  _$CollectionSummaryCopyWithImpl(this._self, this._then);

  final CollectionSummary _self;
  final $Res Function(CollectionSummary) _then;

/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? tcgs = null,}) {
  return _then(CollectionSummary(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as CollectionSummaryTotal,tcgs: null == tcgs ? _self.tcgs : tcgs // ignore: cast_nullable_to_non_nullable
as Map<String, CollectionSummaryTcg>,
  ));
}
/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CollectionSummaryTotalCopyWith<$Res> get total {
  
  return $CollectionSummaryTotalCopyWith<$Res>(_self.total, (value) {
    return _then(_self.copyWith(total: value));
  });
}
}


/// Adds pattern-matching-related methods to [CollectionSummary].
extension CollectionSummaryPatterns on CollectionSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionSummary value)  $default,){
final _that = this;
switch (_that) {
case _CollectionSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CollectionSummaryTotal total,  Map<String, CollectionSummaryTcg> tcgs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
return $default(_that.total,_that.tcgs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CollectionSummaryTotal total,  Map<String, CollectionSummaryTcg> tcgs)  $default,) {final _that = this;
switch (_that) {
case _CollectionSummary():
return $default(_that.total,_that.tcgs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CollectionSummaryTotal total,  Map<String, CollectionSummaryTcg> tcgs)?  $default,) {final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
return $default(_that.total,_that.tcgs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionSummary implements CollectionSummary {
  const _CollectionSummary({required this.total, required  Map<String, CollectionSummaryTcg> tcgs}): _tcgs = tcgs;
  factory _CollectionSummary.fromJson(Map<String, dynamic> json) => _$CollectionSummaryFromJson(json);

@override final  CollectionSummaryTotal total;
 final  Map<String, CollectionSummaryTcg> _tcgs;
@override Map<String, CollectionSummaryTcg> get tcgs {
  if (_tcgs is EqualUnmodifiableMapView) return _tcgs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tcgs);
}


/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionSummaryCopyWith<_CollectionSummary> get copyWith => __$CollectionSummaryCopyWithImpl<_CollectionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionSummary&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.tcgs, _tcgs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_tcgs));
}

@override
String toString() {
    return 'CollectionSummary(total: $total, tcgs: $tcgs)';
}


}

/// @nodoc
abstract mixin class _$CollectionSummaryCopyWith<$Res> implements $CollectionSummaryCopyWith<$Res> {
  factory _$CollectionSummaryCopyWith(_CollectionSummary value, $Res Function(_CollectionSummary) _then) = __$CollectionSummaryCopyWithImpl;
@override @useResult
$Res call({
 CollectionSummaryTotal total, Map<String, CollectionSummaryTcg> tcgs
});


@override $CollectionSummaryTotalCopyWith<$Res> get total;

}
/// @nodoc
class __$CollectionSummaryCopyWithImpl<$Res>
    implements _$CollectionSummaryCopyWith<$Res> {
  __$CollectionSummaryCopyWithImpl(this._self, this._then);

  final _CollectionSummary _self;
  final $Res Function(_CollectionSummary) _then;

/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? tcgs = null,}) {
  return _then(_CollectionSummary(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as CollectionSummaryTotal,tcgs: null == tcgs ? _self._tcgs : tcgs // ignore: cast_nullable_to_non_nullable
as Map<String, CollectionSummaryTcg>,
  ));
}

/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CollectionSummaryTotalCopyWith<$Res> get total {
  
  return $CollectionSummaryTotalCopyWith<$Res>(_self.total, (value) {
    return _then(_self.copyWith(total: value));
  });
}
}


/// @nodoc
mixin _$CollectionSummaryTotal {

 double get value; int get collected; int get wishlisted;
/// Create a copy of CollectionSummaryTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionSummaryTotalCopyWith<CollectionSummaryTotal> get copyWith => _$CollectionSummaryTotalCopyWithImpl<CollectionSummaryTotal>(this as CollectionSummaryTotal, _$identity);

  /// Serializes this CollectionSummaryTotal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CollectionSummaryTotal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionSummaryTotal&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.collected, _this.collected) || other.collected == _this.collected)&&(identical(other.wishlisted, _this.wishlisted) || other.wishlisted == _this.wishlisted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CollectionSummaryTotal;
  return Object.hash(runtimeType,_this.value,_this.collected,_this.wishlisted);
}

@override
String toString() {
  final _this = this as CollectionSummaryTotal;
  return 'CollectionSummaryTotal(value: ${_this.value}, collected: ${_this.collected}, wishlisted: ${_this.wishlisted})';
}


}

/// @nodoc
abstract mixin class $CollectionSummaryTotalCopyWith<$Res>  {
  factory $CollectionSummaryTotalCopyWith(CollectionSummaryTotal value, $Res Function(CollectionSummaryTotal) _then) = _$CollectionSummaryTotalCopyWithImpl;
@useResult
$Res call({
 double value, int collected, int wishlisted
});




}
/// @nodoc
class _$CollectionSummaryTotalCopyWithImpl<$Res>
    implements $CollectionSummaryTotalCopyWith<$Res> {
  _$CollectionSummaryTotalCopyWithImpl(this._self, this._then);

  final CollectionSummaryTotal _self;
  final $Res Function(CollectionSummaryTotal) _then;

/// Create a copy of CollectionSummaryTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? collected = null,Object? wishlisted = null,}) {
  return _then(CollectionSummaryTotal(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,wishlisted: null == wishlisted ? _self.wishlisted : wishlisted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionSummaryTotal].
extension CollectionSummaryTotalPatterns on CollectionSummaryTotal {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionSummaryTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionSummaryTotal() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionSummaryTotal value)  $default,){
final _that = this;
switch (_that) {
case _CollectionSummaryTotal():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionSummaryTotal value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionSummaryTotal() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double value,  int collected,  int wishlisted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionSummaryTotal() when $default != null:
return $default(_that.value,_that.collected,_that.wishlisted);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double value,  int collected,  int wishlisted)  $default,) {final _that = this;
switch (_that) {
case _CollectionSummaryTotal():
return $default(_that.value,_that.collected,_that.wishlisted);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double value,  int collected,  int wishlisted)?  $default,) {final _that = this;
switch (_that) {
case _CollectionSummaryTotal() when $default != null:
return $default(_that.value,_that.collected,_that.wishlisted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionSummaryTotal implements CollectionSummaryTotal {
  const _CollectionSummaryTotal({required this.value, required this.collected, required this.wishlisted});
  factory _CollectionSummaryTotal.fromJson(Map<String, dynamic> json) => _$CollectionSummaryTotalFromJson(json);

@override final  double value;
@override final  int collected;
@override final  int wishlisted;

/// Create a copy of CollectionSummaryTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionSummaryTotalCopyWith<_CollectionSummaryTotal> get copyWith => __$CollectionSummaryTotalCopyWithImpl<_CollectionSummaryTotal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionSummaryTotalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionSummaryTotal&&(identical(other.value, value) || other.value == value)&&(identical(other.collected, collected) || other.collected == collected)&&(identical(other.wishlisted, wishlisted) || other.wishlisted == wishlisted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,collected,wishlisted);
}

@override
String toString() {
    return 'CollectionSummaryTotal(value: $value, collected: $collected, wishlisted: $wishlisted)';
}


}

/// @nodoc
abstract mixin class _$CollectionSummaryTotalCopyWith<$Res> implements $CollectionSummaryTotalCopyWith<$Res> {
  factory _$CollectionSummaryTotalCopyWith(_CollectionSummaryTotal value, $Res Function(_CollectionSummaryTotal) _then) = __$CollectionSummaryTotalCopyWithImpl;
@override @useResult
$Res call({
 double value, int collected, int wishlisted
});




}
/// @nodoc
class __$CollectionSummaryTotalCopyWithImpl<$Res>
    implements _$CollectionSummaryTotalCopyWith<$Res> {
  __$CollectionSummaryTotalCopyWithImpl(this._self, this._then);

  final _CollectionSummaryTotal _self;
  final $Res Function(_CollectionSummaryTotal) _then;

/// Create a copy of CollectionSummaryTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? collected = null,Object? wishlisted = null,}) {
  return _then(_CollectionSummaryTotal(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,wishlisted: null == wishlisted ? _self.wishlisted : wishlisted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CollectionSummaryTcg {

 String get name; double get value; int get collected; int get wishlisted; TcgSet get latestSet;
/// Create a copy of CollectionSummaryTcg
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionSummaryTcgCopyWith<CollectionSummaryTcg> get copyWith => _$CollectionSummaryTcgCopyWithImpl<CollectionSummaryTcg>(this as CollectionSummaryTcg, _$identity);

  /// Serializes this CollectionSummaryTcg to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CollectionSummaryTcg;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionSummaryTcg&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.collected, _this.collected) || other.collected == _this.collected)&&(identical(other.wishlisted, _this.wishlisted) || other.wishlisted == _this.wishlisted)&&(identical(other.latestSet, _this.latestSet) || other.latestSet == _this.latestSet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CollectionSummaryTcg;
  return Object.hash(runtimeType,_this.name,_this.value,_this.collected,_this.wishlisted,_this.latestSet);
}

@override
String toString() {
  final _this = this as CollectionSummaryTcg;
  return 'CollectionSummaryTcg(name: ${_this.name}, value: ${_this.value}, collected: ${_this.collected}, wishlisted: ${_this.wishlisted}, latestSet: ${_this.latestSet})';
}


}

/// @nodoc
abstract mixin class $CollectionSummaryTcgCopyWith<$Res>  {
  factory $CollectionSummaryTcgCopyWith(CollectionSummaryTcg value, $Res Function(CollectionSummaryTcg) _then) = _$CollectionSummaryTcgCopyWithImpl;
@useResult
$Res call({
 String name, double value, int collected, int wishlisted, TcgSet latestSet
});


$TcgSetCopyWith<$Res> get latestSet;

}
/// @nodoc
class _$CollectionSummaryTcgCopyWithImpl<$Res>
    implements $CollectionSummaryTcgCopyWith<$Res> {
  _$CollectionSummaryTcgCopyWithImpl(this._self, this._then);

  final CollectionSummaryTcg _self;
  final $Res Function(CollectionSummaryTcg) _then;

/// Create a copy of CollectionSummaryTcg
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? value = null,Object? collected = null,Object? wishlisted = null,Object? latestSet = null,}) {
  return _then(CollectionSummaryTcg(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,wishlisted: null == wishlisted ? _self.wishlisted : wishlisted // ignore: cast_nullable_to_non_nullable
as int,latestSet: null == latestSet ? _self.latestSet : latestSet // ignore: cast_nullable_to_non_nullable
as TcgSet,
  ));
}
/// Create a copy of CollectionSummaryTcg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TcgSetCopyWith<$Res> get latestSet {
  
  return $TcgSetCopyWith<$Res>(_self.latestSet, (value) {
    return _then(_self.copyWith(latestSet: value));
  });
}
}


/// Adds pattern-matching-related methods to [CollectionSummaryTcg].
extension CollectionSummaryTcgPatterns on CollectionSummaryTcg {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionSummaryTcg value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionSummaryTcg() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionSummaryTcg value)  $default,){
final _that = this;
switch (_that) {
case _CollectionSummaryTcg():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionSummaryTcg value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionSummaryTcg() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double value,  int collected,  int wishlisted,  TcgSet latestSet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionSummaryTcg() when $default != null:
return $default(_that.name,_that.value,_that.collected,_that.wishlisted,_that.latestSet);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double value,  int collected,  int wishlisted,  TcgSet latestSet)  $default,) {final _that = this;
switch (_that) {
case _CollectionSummaryTcg():
return $default(_that.name,_that.value,_that.collected,_that.wishlisted,_that.latestSet);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double value,  int collected,  int wishlisted,  TcgSet latestSet)?  $default,) {final _that = this;
switch (_that) {
case _CollectionSummaryTcg() when $default != null:
return $default(_that.name,_that.value,_that.collected,_that.wishlisted,_that.latestSet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionSummaryTcg implements CollectionSummaryTcg {
  const _CollectionSummaryTcg({required this.name, required this.value, required this.collected, required this.wishlisted, required this.latestSet});
  factory _CollectionSummaryTcg.fromJson(Map<String, dynamic> json) => _$CollectionSummaryTcgFromJson(json);

@override final  String name;
@override final  double value;
@override final  int collected;
@override final  int wishlisted;
@override final  TcgSet latestSet;

/// Create a copy of CollectionSummaryTcg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionSummaryTcgCopyWith<_CollectionSummaryTcg> get copyWith => __$CollectionSummaryTcgCopyWithImpl<_CollectionSummaryTcg>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionSummaryTcgToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionSummaryTcg&&(identical(other.name, name) || other.name == name)&&(identical(other.value, value) || other.value == value)&&(identical(other.collected, collected) || other.collected == collected)&&(identical(other.wishlisted, wishlisted) || other.wishlisted == wishlisted)&&(identical(other.latestSet, latestSet) || other.latestSet == latestSet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,value,collected,wishlisted,latestSet);
}

@override
String toString() {
    return 'CollectionSummaryTcg(name: $name, value: $value, collected: $collected, wishlisted: $wishlisted, latestSet: $latestSet)';
}


}

/// @nodoc
abstract mixin class _$CollectionSummaryTcgCopyWith<$Res> implements $CollectionSummaryTcgCopyWith<$Res> {
  factory _$CollectionSummaryTcgCopyWith(_CollectionSummaryTcg value, $Res Function(_CollectionSummaryTcg) _then) = __$CollectionSummaryTcgCopyWithImpl;
@override @useResult
$Res call({
 String name, double value, int collected, int wishlisted, TcgSet latestSet
});


@override $TcgSetCopyWith<$Res> get latestSet;

}
/// @nodoc
class __$CollectionSummaryTcgCopyWithImpl<$Res>
    implements _$CollectionSummaryTcgCopyWith<$Res> {
  __$CollectionSummaryTcgCopyWithImpl(this._self, this._then);

  final _CollectionSummaryTcg _self;
  final $Res Function(_CollectionSummaryTcg) _then;

/// Create a copy of CollectionSummaryTcg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? value = null,Object? collected = null,Object? wishlisted = null,Object? latestSet = null,}) {
  return _then(_CollectionSummaryTcg(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,wishlisted: null == wishlisted ? _self.wishlisted : wishlisted // ignore: cast_nullable_to_non_nullable
as int,latestSet: null == latestSet ? _self.latestSet : latestSet // ignore: cast_nullable_to_non_nullable
as TcgSet,
  ));
}

/// Create a copy of CollectionSummaryTcg
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TcgSetCopyWith<$Res> get latestSet {
  
  return $TcgSetCopyWith<$Res>(_self.latestSet, (value) {
    return _then(_self.copyWith(latestSet: value));
  });
}
}

// dart format on
