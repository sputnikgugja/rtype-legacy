#include "rtype_legacy.h"

VALUE rb_mRtype, rb_mRtypeLegacy, rb_mRtypeBehavior, rb_cRtypeBehaviorBase, rb_eRtypeArgumentTypeError, rb_eRtypeTypeSignatureError, rb_eRtypeReturnTypeError;
static ID id_to_s, id_keys, id_eqeq, id_include, id_valid, id_call, id_key;

VALUE
rb_rtype_valid(VALUE self, VALUE expected, VALUE value) {
	long i;
	VALUE e_keys;
	VALUE v_keys;
	
	switch(TYPE(expected)) {
		case T_MODULE:
		case T_CLASS:
			return rb_obj_is_kind_of(value, expected) ? Qtrue : Qfalse;
		case T_SYMBOL:
			return rb_respond_to(value, rb_to_id(expected)) ? Qtrue : Qfalse;
		case T_REGEXP:
			return rb_reg_match( expected, rb_funcall(value, id_to_s, 0) ) != Qnil ? Qtrue : Qfalse;
		case T_HASH:
			if( !RB_TYPE_P(value, T_HASH) ) {
				return Qfalse;
			}
			e_keys = rb_funcall(expected, id_keys, 0);
			v_keys = rb_funcall(value, id_keys, 0);
			if( !RTEST(rb_funcall(e_keys, id_eqeq, 1, v_keys)) ) {
				return Qfalse;
			}
			
			for(i = 0; i < RARRAY_LEN(e_keys); i++) {
				VALUE e_k = rb_ary_entry(e_keys, i);
				VALUE e_v = rb_hash_aref(expected, e_k);
				if(rb_rtype_valid(self, e_v, rb_hash_aref(value, e_k)) == Qfalse) {
					return Qfalse;
				}
			}
			return Qtrue;
		case T_ARRAY:
			for(i = 0; i < RARRAY_LEN(expected); i++) {
				VALUE e = rb_ary_entry(expected, i);
				VALUE valid = rb_rtype_valid(self, e, value);
				if(valid == Qtrue) {
					return Qtrue;
				}
			}
			return Qfalse;
		case T_TRUE:
			return RTEST(value) ? Qtrue : Qfalse;
		case T_FALSE:
			return !RTEST(value) ? Qtrue : Qfalse;
		case T_NIL:
			return value == Qnil;
		default:
			if(rb_obj_is_kind_of(expected, rb_cRange)) {
				return rb_funcall(expected, id_include, 1, value);
			}
			else if(rb_obj_is_kind_of(expected, rb_cProc)) {
				return RTEST(rb_funcall(expected, id_call, 1, value)) ? Qtrue : Qfalse;
			}
			else if( RTEST(rb_obj_is_kind_of(expected, rb_cRtypeBehaviorBase)) ) {
				return rb_funcall(expected, id_valid, 1, value);
			}
			else {
				VALUE str = rb_any_to_s(expected);
				rb_raise(rb_eRtypeTypeSignatureError, "Invalid type signature: Unknown type behavior %s", StringValueCStr(str));
				return Qfalse;
			}
	}
}

VALUE
rb_rtype_assert_arguments_type(VALUE self, VALUE expected_args, VALUE args) {
	// 'for' loop initial declarations are only allowed in c99 mode
	long i;
	long e_len = RARRAY_LEN(expected_args);
	for(i = 0; i < RARRAY_LEN(args); i++) {
		VALUE e, v;
		if(i >= e_len) {
			break;
		}
		e = rb_ary_entry(expected_args, i);
		v = rb_ary_entry(args, i);
		if( !RTEST(rb_rtype_valid(self, e, v)) ) {
			VALUE msg = rb_funcall(rb_mRtype, rb_intern("arg_type_error_message"), 3, LONG2FIX(i), e, v);
			rb_raise(rb_eRtypeArgumentTypeError, "%s", StringValueCStr(msg));
		}
	}
	return Qnil;
}

/*
static int
kwargs_do_each(VALUE key, VALUE val, VALUE in) {
	if( RTEST(rb_funcall(in, id_key, 1, key)) ) {
		VALUE expected = rb_hash_aref(in, key);
		if( !RTEST(rb_rtype_valid((VALUE) NULL, expected, val)) ) {
			VALUE msg = rb_funcall(rb_mRtype, rb_intern("kwarg_type_error_message"), 3, key, expected, val);
			rb_raise(rb_eRtypeArgumentTypeError, "%s", StringValueCStr(msg));
		}
	}
	return ST_CONTINUE;
}

VALUE
rb_rtype_assert_arguments_type_with_keywords(VALUE self, VALUE expected_args, VALUE args, VALUE expected_kwargs, VALUE kwargs) {
	rb_rtype_assert_arguments_type(self, expected_args, args);
	rb_hash_foreach(kwargs, kwargs_do_each, expected_kwargs);
	return Qnil;
}
*/

VALUE
rb_rtype_assert_return_type(VALUE self, VALUE expected, VALUE result) {
	if( !RTEST(rb_rtype_valid(self, expected, result)) ) {
		VALUE msg = rb_funcall(rb_mRtype, rb_intern("type_error_message"), 2, expected, result);
		rb_raise(rb_eRtypeReturnTypeError, "for return:\n%s", StringValueCStr(msg));
	}
	return Qnil;
}

void Init_rtype_legacy_native(void) {
	rb_mRtype = rb_define_module("Rtype");
	rb_mRtypeLegacy = rb_define_module_under(rb_mRtype, "Legacy");
	rb_mRtypeBehavior = rb_define_module_under(rb_mRtype, "Behavior");
	rb_cRtypeBehaviorBase = rb_define_class_under(rb_mRtypeBehavior, "Base", rb_cObject);
	rb_eRtypeArgumentTypeError = rb_define_class_under(rb_mRtype, "ArgumentTypeError", rb_eArgError);
	rb_eRtypeTypeSignatureError = rb_define_class_under(rb_mRtype, "TypeSignatureError", rb_eArgError);
	rb_eRtypeReturnTypeError = rb_define_class_under(rb_mRtype, "ReturnTypeError", rb_eStandardError);
	
	rb_define_const(rb_mRtypeLegacy, "NATIVE_EXT_VERSION", rb_str_new2(RTYPE_NATIVE_EXT_VERSION));

	id_to_s = rb_intern("to_s");
	id_keys = rb_intern("keys");
	id_eqeq = rb_intern("==");
	id_include = rb_intern("include?");
	id_valid = rb_intern("valid?");
	id_call = rb_intern("call");
	id_key = rb_intern("key?");

	rb_define_method(rb_mRtype, "valid?", rb_rtype_valid, 2);
	rb_define_method(rb_mRtype, "assert_arguments_type", rb_rtype_assert_arguments_type, 2);
	// rb_define_method(rb_mRtype, "assert_arguments_type_with_keywords", rb_rtype_assert_arguments_type_with_keywords, 4);
	rb_define_method(rb_mRtype, "assert_return_type", rb_rtype_assert_return_type, 2);
}
