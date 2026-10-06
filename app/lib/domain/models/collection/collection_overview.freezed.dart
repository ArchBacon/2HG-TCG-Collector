// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection_overview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CollectionOverview {

@JsonKey(readValue: _self) CollectionSummaryTcg get summary; List<CollectionOverviewBlock> get blocks;
/// Create a copy of CollectionOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionOverviewCopyWith<CollectionOverview> get copyWith => _$CollectionOverviewCopyWithImpl<CollectionOverview>(this as CollectionOverview, _$identity);

  /// Serializes this CollectionOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CollectionOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionOverview&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.blocks, _this.blocks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CollectionOverview;
  return Object.hash(runtimeType,_this.summary,const DeepCollectionEquality().hash(_this.blocks));
}

@override
String toString() {
  final _this = this as CollectionOverview;
  return 'CollectionOverview(summary: ${_this.summary}, blocks: ${_this.blocks})';
}


}

/// @nodoc
abstract mixin class $CollectionOverviewCopyWith<$Res>  {
  factory $CollectionOverviewCopyWith(CollectionOverview value, $Res Function(CollectionOverview) _then) = _$CollectionOverviewCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: _self) CollectionSummaryTcg summary, List<CollectionOverviewBlock> blocks
});


$CollectionSummaryTcgCopyWith<$Res> get summary;

}
/// @nodoc
class _$CollectionOverviewCopyWithImpl<$Res>
    implements $CollectionOverviewCopyWith<$Res> {
  _$CollectionOverviewCopyWithImpl(this._self, this._then);

  final CollectionOverview _self;
  final $Res Function(CollectionOverview) _then;

/// Create a copy of CollectionOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? blocks = null,}) {
  return _then(CollectionOverview(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as CollectionSummaryTcg,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<CollectionOverviewBlock>,
  ));
}
/// Create a copy of CollectionOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CollectionSummaryTcgCopyWith<$Res> get summary {
  
  return $CollectionSummaryTcgCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [CollectionOverview].
extension CollectionOverviewPatterns on CollectionOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionOverview value)  $default,){
final _that = this;
switch (_that) {
case _CollectionOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionOverview value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: _self)  CollectionSummaryTcg summary,  List<CollectionOverviewBlock> blocks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionOverview() when $default != null:
return $default(_that.summary,_that.blocks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: _self)  CollectionSummaryTcg summary,  List<CollectionOverviewBlock> blocks)  $default,) {final _that = this;
switch (_that) {
case _CollectionOverview():
return $default(_that.summary,_that.blocks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: _self)  CollectionSummaryTcg summary,  List<CollectionOverviewBlock> blocks)?  $default,) {final _that = this;
switch (_that) {
case _CollectionOverview() when $default != null:
return $default(_that.summary,_that.blocks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionOverview implements CollectionOverview {
  const _CollectionOverview({@JsonKey(readValue: _self) required this.summary, required  List<CollectionOverviewBlock> blocks}): _blocks = blocks;
  factory _CollectionOverview.fromJson(Map<String, dynamic> json) => _$CollectionOverviewFromJson(json);

@override@JsonKey(readValue: _self) final  CollectionSummaryTcg summary;
 final  List<CollectionOverviewBlock> _blocks;
@override List<CollectionOverviewBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}


/// Create a copy of CollectionOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionOverviewCopyWith<_CollectionOverview> get copyWith => __$CollectionOverviewCopyWithImpl<_CollectionOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionOverview&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.blocks, _blocks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_blocks));
}

@override
String toString() {
    return 'CollectionOverview(summary: $summary, blocks: $blocks)';
}


}

/// @nodoc
abstract mixin class _$CollectionOverviewCopyWith<$Res> implements $CollectionOverviewCopyWith<$Res> {
  factory _$CollectionOverviewCopyWith(_CollectionOverview value, $Res Function(_CollectionOverview) _then) = __$CollectionOverviewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: _self) CollectionSummaryTcg summary, List<CollectionOverviewBlock> blocks
});


@override $CollectionSummaryTcgCopyWith<$Res> get summary;

}
/// @nodoc
class __$CollectionOverviewCopyWithImpl<$Res>
    implements _$CollectionOverviewCopyWith<$Res> {
  __$CollectionOverviewCopyWithImpl(this._self, this._then);

  final _CollectionOverview _self;
  final $Res Function(_CollectionOverview) _then;

/// Create a copy of CollectionOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? blocks = null,}) {
  return _then(_CollectionOverview(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as CollectionSummaryTcg,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<CollectionOverviewBlock>,
  ));
}

/// Create a copy of CollectionOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CollectionSummaryTcgCopyWith<$Res> get summary {
  
  return $CollectionSummaryTcgCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// @nodoc
mixin _$CollectionOverviewBlock {

 String? get block; List<CollectionOverviewSet> get sets;
/// Create a copy of CollectionOverviewBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionOverviewBlockCopyWith<CollectionOverviewBlock> get copyWith => _$CollectionOverviewBlockCopyWithImpl<CollectionOverviewBlock>(this as CollectionOverviewBlock, _$identity);

  /// Serializes this CollectionOverviewBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CollectionOverviewBlock;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionOverviewBlock&&(identical(other.block, _this.block) || other.block == _this.block)&&const DeepCollectionEquality().equals(other.sets, _this.sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CollectionOverviewBlock;
  return Object.hash(runtimeType,_this.block,const DeepCollectionEquality().hash(_this.sets));
}

@override
String toString() {
  final _this = this as CollectionOverviewBlock;
  return 'CollectionOverviewBlock(block: ${_this.block}, sets: ${_this.sets})';
}


}

/// @nodoc
abstract mixin class $CollectionOverviewBlockCopyWith<$Res>  {
  factory $CollectionOverviewBlockCopyWith(CollectionOverviewBlock value, $Res Function(CollectionOverviewBlock) _then) = _$CollectionOverviewBlockCopyWithImpl;
@useResult
$Res call({
 String? block, List<CollectionOverviewSet> sets
});




}
/// @nodoc
class _$CollectionOverviewBlockCopyWithImpl<$Res>
    implements $CollectionOverviewBlockCopyWith<$Res> {
  _$CollectionOverviewBlockCopyWithImpl(this._self, this._then);

  final CollectionOverviewBlock _self;
  final $Res Function(CollectionOverviewBlock) _then;

/// Create a copy of CollectionOverviewBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? block = freezed,Object? sets = null,}) {
  return _then(CollectionOverviewBlock(
block: freezed == block ? _self.block : block // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<CollectionOverviewSet>,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionOverviewBlock].
extension CollectionOverviewBlockPatterns on CollectionOverviewBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionOverviewBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionOverviewBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionOverviewBlock value)  $default,){
final _that = this;
switch (_that) {
case _CollectionOverviewBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionOverviewBlock value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionOverviewBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? block,  List<CollectionOverviewSet> sets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionOverviewBlock() when $default != null:
return $default(_that.block,_that.sets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? block,  List<CollectionOverviewSet> sets)  $default,) {final _that = this;
switch (_that) {
case _CollectionOverviewBlock():
return $default(_that.block,_that.sets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? block,  List<CollectionOverviewSet> sets)?  $default,) {final _that = this;
switch (_that) {
case _CollectionOverviewBlock() when $default != null:
return $default(_that.block,_that.sets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionOverviewBlock implements CollectionOverviewBlock {
  const _CollectionOverviewBlock({required this.block, required  List<CollectionOverviewSet> sets}): _sets = sets;
  factory _CollectionOverviewBlock.fromJson(Map<String, dynamic> json) => _$CollectionOverviewBlockFromJson(json);

@override final  String? block;
 final  List<CollectionOverviewSet> _sets;
@override List<CollectionOverviewSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}


/// Create a copy of CollectionOverviewBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionOverviewBlockCopyWith<_CollectionOverviewBlock> get copyWith => __$CollectionOverviewBlockCopyWithImpl<_CollectionOverviewBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionOverviewBlockToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionOverviewBlock&&(identical(other.block, block) || other.block == block)&&const DeepCollectionEquality().equals(other.sets, _sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,block,const DeepCollectionEquality().hash(_sets));
}

@override
String toString() {
    return 'CollectionOverviewBlock(block: $block, sets: $sets)';
}


}

/// @nodoc
abstract mixin class _$CollectionOverviewBlockCopyWith<$Res> implements $CollectionOverviewBlockCopyWith<$Res> {
  factory _$CollectionOverviewBlockCopyWith(_CollectionOverviewBlock value, $Res Function(_CollectionOverviewBlock) _then) = __$CollectionOverviewBlockCopyWithImpl;
@override @useResult
$Res call({
 String? block, List<CollectionOverviewSet> sets
});




}
/// @nodoc
class __$CollectionOverviewBlockCopyWithImpl<$Res>
    implements _$CollectionOverviewBlockCopyWith<$Res> {
  __$CollectionOverviewBlockCopyWithImpl(this._self, this._then);

  final _CollectionOverviewBlock _self;
  final $Res Function(_CollectionOverviewBlock) _then;

/// Create a copy of CollectionOverviewBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? block = freezed,Object? sets = null,}) {
  return _then(_CollectionOverviewBlock(
block: freezed == block ? _self.block : block // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<CollectionOverviewSet>,
  ));
}


}


/// @nodoc
mixin _$CollectionOverviewSet {

@JsonKey(readValue: _self) TcgSet get set; int get collected;
/// Create a copy of CollectionOverviewSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionOverviewSetCopyWith<CollectionOverviewSet> get copyWith => _$CollectionOverviewSetCopyWithImpl<CollectionOverviewSet>(this as CollectionOverviewSet, _$identity);

  /// Serializes this CollectionOverviewSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CollectionOverviewSet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionOverviewSet&&(identical(other.set, _this.set) || other.set == _this.set)&&(identical(other.collected, _this.collected) || other.collected == _this.collected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CollectionOverviewSet;
  return Object.hash(runtimeType,_this.set,_this.collected);
}

@override
String toString() {
  final _this = this as CollectionOverviewSet;
  return 'CollectionOverviewSet(set: ${_this.set}, collected: ${_this.collected})';
}


}

/// @nodoc
abstract mixin class $CollectionOverviewSetCopyWith<$Res>  {
  factory $CollectionOverviewSetCopyWith(CollectionOverviewSet value, $Res Function(CollectionOverviewSet) _then) = _$CollectionOverviewSetCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: _self) TcgSet set, int collected
});


$TcgSetCopyWith<$Res> get set;

}
/// @nodoc
class _$CollectionOverviewSetCopyWithImpl<$Res>
    implements $CollectionOverviewSetCopyWith<$Res> {
  _$CollectionOverviewSetCopyWithImpl(this._self, this._then);

  final CollectionOverviewSet _self;
  final $Res Function(CollectionOverviewSet) _then;

/// Create a copy of CollectionOverviewSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? set = null,Object? collected = null,}) {
  return _then(CollectionOverviewSet(
set: null == set ? _self.set : set // ignore: cast_nullable_to_non_nullable
as TcgSet,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CollectionOverviewSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TcgSetCopyWith<$Res> get set {
  
  return $TcgSetCopyWith<$Res>(_self.set, (value) {
    return _then(_self.copyWith(set: value));
  });
}
}


/// Adds pattern-matching-related methods to [CollectionOverviewSet].
extension CollectionOverviewSetPatterns on CollectionOverviewSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionOverviewSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionOverviewSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionOverviewSet value)  $default,){
final _that = this;
switch (_that) {
case _CollectionOverviewSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionOverviewSet value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionOverviewSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: _self)  TcgSet set,  int collected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionOverviewSet() when $default != null:
return $default(_that.set,_that.collected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: _self)  TcgSet set,  int collected)  $default,) {final _that = this;
switch (_that) {
case _CollectionOverviewSet():
return $default(_that.set,_that.collected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: _self)  TcgSet set,  int collected)?  $default,) {final _that = this;
switch (_that) {
case _CollectionOverviewSet() when $default != null:
return $default(_that.set,_that.collected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionOverviewSet implements CollectionOverviewSet {
  const _CollectionOverviewSet({@JsonKey(readValue: _self) required this.set, required this.collected});
  factory _CollectionOverviewSet.fromJson(Map<String, dynamic> json) => _$CollectionOverviewSetFromJson(json);

@override@JsonKey(readValue: _self) final  TcgSet set;
@override final  int collected;

/// Create a copy of CollectionOverviewSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionOverviewSetCopyWith<_CollectionOverviewSet> get copyWith => __$CollectionOverviewSetCopyWithImpl<_CollectionOverviewSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionOverviewSetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionOverviewSet&&(identical(other.set, set) || other.set == set)&&(identical(other.collected, collected) || other.collected == collected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,set,collected);
}

@override
String toString() {
    return 'CollectionOverviewSet(set: $set, collected: $collected)';
}


}

/// @nodoc
abstract mixin class _$CollectionOverviewSetCopyWith<$Res> implements $CollectionOverviewSetCopyWith<$Res> {
  factory _$CollectionOverviewSetCopyWith(_CollectionOverviewSet value, $Res Function(_CollectionOverviewSet) _then) = __$CollectionOverviewSetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: _self) TcgSet set, int collected
});


@override $TcgSetCopyWith<$Res> get set;

}
/// @nodoc
class __$CollectionOverviewSetCopyWithImpl<$Res>
    implements _$CollectionOverviewSetCopyWith<$Res> {
  __$CollectionOverviewSetCopyWithImpl(this._self, this._then);

  final _CollectionOverviewSet _self;
  final $Res Function(_CollectionOverviewSet) _then;

/// Create a copy of CollectionOverviewSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? set = null,Object? collected = null,}) {
  return _then(_CollectionOverviewSet(
set: null == set ? _self.set : set // ignore: cast_nullable_to_non_nullable
as TcgSet,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CollectionOverviewSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TcgSetCopyWith<$Res> get set {
  
  return $TcgSetCopyWith<$Res>(_self.set, (value) {
    return _then(_self.copyWith(set: value));
  });
}
}

// dart format on
