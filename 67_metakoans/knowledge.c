#include "ruby.h"

static ID meth_name_id;
static ID to_s_id;

static VALUE evalulator;
static ID evalualte_id;

static VALUE current_method(){
    VALUE sym = rb_funcall(rb_cObject, meth_name_id, 0);
    return rb_funcall(sym, to_s_id, 0);
}

static char* ivar_name() {
    VALUE name = current_method();
    char last = RSTRING_PTR(name)[RSTRING_LEN(name)-1];
    char* ivar;
    int strip = 0;
    size_t len;
    
    if(last == '=' || last == '?'){
        strip = 1;
    }
    
    len = RSTRING_LEN(name) + 2 - strip;
    ivar = malloc(len);
    memcpy(ivar + 1, RSTRING_PTR(name), len - 2);
    ivar[0] = '@';
    ivar[len - 1] = 0;
    
    return ivar;
}

static VALUE get(VALUE self){    
    char* ivar = ivar_name();
    VALUE val = Qnil;
    
    if (rb_ivar_defined(self, rb_intern(ivar))) {
        val = rb_iv_get(self, ivar);
    }
    else {        
        VALUE class = RBASIC(self)->klass; //need to check singletons / metaclasses etc, so rb_obj_class is no good
        while (val == Qnil && class != rb_cObject) {
            //if it's an ICLASS, we need to check the original
            VALUE check_class = (RBASIC(class)->flags & T_ICLASS) ? RBASIC(class)->klass : class;
            val = rb_iv_get(check_class, ivar +1);
            class = RCLASS_SUPER(class);
        }
        
        if (rb_obj_is_proc(val)) {
            val = rb_funcall(evalulator, evalualte_id, 2, self, val);
        }
    }
    
    free(ivar);
    return val;
}

static VALUE set(VALUE self, VALUE new_val){
    char* ivar = ivar_name();
    rb_iv_set(self, ivar, new_val);
    
    free(ivar);
    return Qnil;
}

static VALUE attribute(VALUE, VALUE);

static int hash_entry(VALUE key, VALUE value, VALUE mod){
    attribute(mod, key);
    rb_iv_set(mod, StringValuePtr(key), value);
    return ST_CONTINUE;
}

static VALUE attribute(VALUE self, VALUE name){
    
    VALUE tmp = rb_check_hash_type(name);
    if (!NIL_P(tmp)) {
        rb_hash_foreach(tmp, hash_entry, self);
        return Qnil;
    }
    
    char* c_name = StringValuePtr(name);
    size_t name_len = RSTRING_LEN(name);
    char* query = malloc(name_len + 2);
    memcpy(query, c_name, name_len);
    query[name_len + 1] = 0;
    
    rb_define_method(self, c_name, get, 0);
    query[name_len] = '?';
    rb_define_method(self, query, get, 0);
    query[name_len] = '=';
    rb_define_method(self, query, set, 1);
    
    free(query);
    
    //set default
    VALUE default_val = Qnil;
    if (rb_block_given_p()) {
        default_val = rb_block_proc();
    }
    rb_iv_set(self, c_name, default_val);
    
    return Qnil;
}

void Init_knowledge() {
    meth_name_id = rb_intern("__method__");
    to_s_id = rb_intern("to_s");
    
    //the only way to evaluate a block in another context is in Ruby...
    evalulator = rb_class_new_instance(0, NULL, rb_cObject);
    VALUE eval_method = rb_str_new2("def eval_in_context(context, proc); context.instance_eval &proc;end");
    rb_obj_instance_eval(1, &eval_method, evalulator);
    evalualte_id = rb_intern("eval_in_context");
    
    rb_define_method(rb_cModule, "attribute", attribute, 1);
}