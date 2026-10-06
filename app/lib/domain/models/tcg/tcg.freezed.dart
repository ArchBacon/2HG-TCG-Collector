// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tcg.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TcgSet {

 String get id; String? get lang; String get code; String get name; int? get cardCount; DateTime? get releasedAt; Map<String, String?> get images;
/// Create a copy of TcgSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TcgSetCopyWith<TcgSet> get copyWith => _$TcgSetCopyWithImpl<TcgSet>(this as TcgSet, _$identity);

  /// Serializes this TcgSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TcgSet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TcgSet&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lang, _this.lang) || other.lang == _this.lang)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.cardCount, _this.cardCount) || other.cardCount == _this.cardCount)&&(identical(other.releasedAt, _this.releasedAt) || other.releasedAt == _this.releasedAt)&&const DeepCollectionEquality().equals(other.images, _this.images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TcgSet;
  return Object.hash(runtimeType,_this.id,_this.lang,_this.code,_this.name,_this.cardCount,_this.releasedAt,const DeepCollectionEquality().hash(_this.images));
}

@override
String toString() {
  final _this = this as TcgSet;
  return 'TcgSet(id: ${_this.id}, lang: ${_this.lang}, code: ${_this.code}, name: ${_this.name}, cardCount: ${_this.cardCount}, releasedAt: ${_this.releasedAt}, images: ${_this.images})';
}


}

/// @nodoc
abstract mixin class $TcgSetCopyWith<$Res>  {
  factory $TcgSetCopyWith(TcgSet value, $Res Function(TcgSet) _then) = _$TcgSetCopyWithImpl;
@useResult
$Res call({
 String id, String? lang, String code, String name, int? cardCount, DateTime? releasedAt, Map<String, String?> images
});




}
/// @nodoc
class _$TcgSetCopyWithImpl<$Res>
    implements $TcgSetCopyWith<$Res> {
  _$TcgSetCopyWithImpl(this._self, this._then);

  final TcgSet _self;
  final $Res Function(TcgSet) _then;

/// Create a copy of TcgSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lang = freezed,Object? code = null,Object? name = null,Object? cardCount = freezed,Object? releasedAt = freezed,Object? images = null,}) {
  return _then(TcgSet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cardCount: freezed == cardCount ? _self.cardCount : cardCount // ignore: cast_nullable_to_non_nullable
as int?,releasedAt: freezed == releasedAt ? _self.releasedAt : releasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,
  ));
}

}


/// Adds pattern-matching-related methods to [TcgSet].
extension TcgSetPatterns on TcgSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TcgSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TcgSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TcgSet value)  $default,){
final _that = this;
switch (_that) {
case _TcgSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TcgSet value)?  $default,){
final _that = this;
switch (_that) {
case _TcgSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? lang,  String code,  String name,  int? cardCount,  DateTime? releasedAt,  Map<String, String?> images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TcgSet() when $default != null:
return $default(_that.id,_that.lang,_that.code,_that.name,_that.cardCount,_that.releasedAt,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? lang,  String code,  String name,  int? cardCount,  DateTime? releasedAt,  Map<String, String?> images)  $default,) {final _that = this;
switch (_that) {
case _TcgSet():
return $default(_that.id,_that.lang,_that.code,_that.name,_that.cardCount,_that.releasedAt,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? lang,  String code,  String name,  int? cardCount,  DateTime? releasedAt,  Map<String, String?> images)?  $default,) {final _that = this;
switch (_that) {
case _TcgSet() when $default != null:
return $default(_that.id,_that.lang,_that.code,_that.name,_that.cardCount,_that.releasedAt,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TcgSet implements TcgSet {
  const _TcgSet({required this.id, required this.lang, required this.code, required this.name, required this.cardCount, required this.releasedAt, required  Map<String, String?> images}): _images = images;
  factory _TcgSet.fromJson(Map<String, dynamic> json) => _$TcgSetFromJson(json);

@override final  String id;
@override final  String? lang;
@override final  String code;
@override final  String name;
@override final  int? cardCount;
@override final  DateTime? releasedAt;
 final  Map<String, String?> _images;
@override Map<String, String?> get images {
  if (_images is EqualUnmodifiableMapView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_images);
}


/// Create a copy of TcgSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TcgSetCopyWith<_TcgSet> get copyWith => __$TcgSetCopyWithImpl<_TcgSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TcgSetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TcgSet&&(identical(other.id, id) || other.id == id)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.cardCount, cardCount) || other.cardCount == cardCount)&&(identical(other.releasedAt, releasedAt) || other.releasedAt == releasedAt)&&const DeepCollectionEquality().equals(other.images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,lang,code,name,cardCount,releasedAt,const DeepCollectionEquality().hash(_images));
}

@override
String toString() {
    return 'TcgSet(id: $id, lang: $lang, code: $code, name: $name, cardCount: $cardCount, releasedAt: $releasedAt, images: $images)';
}


}

/// @nodoc
abstract mixin class _$TcgSetCopyWith<$Res> implements $TcgSetCopyWith<$Res> {
  factory _$TcgSetCopyWith(_TcgSet value, $Res Function(_TcgSet) _then) = __$TcgSetCopyWithImpl;
@override @useResult
$Res call({
 String id, String? lang, String code, String name, int? cardCount, DateTime? releasedAt, Map<String, String?> images
});




}
/// @nodoc
class __$TcgSetCopyWithImpl<$Res>
    implements _$TcgSetCopyWith<$Res> {
  __$TcgSetCopyWithImpl(this._self, this._then);

  final _TcgSet _self;
  final $Res Function(_TcgSet) _then;

/// Create a copy of TcgSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lang = freezed,Object? code = null,Object? name = null,Object? cardCount = freezed,Object? releasedAt = freezed,Object? images = null,}) {
  return _then(_TcgSet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cardCount: freezed == cardCount ? _self.cardCount : cardCount // ignore: cast_nullable_to_non_nullable
as int?,releasedAt: freezed == releasedAt ? _self.releasedAt : releasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,
  ));
}


}

// dart format on
