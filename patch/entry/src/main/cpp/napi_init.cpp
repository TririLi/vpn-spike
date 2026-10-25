#include "napi/native_api.h"
#include <dlfcn.h>
#include <cstring>
#include <string>

typedef int (*AddFn)(int, int);

static std::string GoAdd(int a, int b, bool *ok) {
    void *h = dlopen("libgoadd.so", RTLD_NOW);
    if (h == nullptr) {
        *ok = false;
        const char *e = dlerror();
        return e == nullptr ? "dlopen failed" : std::string(e);
    }
    AddFn fn = (AddFn)dlsym(h, "Add");
    if (fn == nullptr) {
        *ok = false;
        dlclose(h);
        return "dlsym Add failed";
    }
    int r = fn(a, b);
    dlclose(h);
    *ok = true;
    return std::to_string(r);
}

static napi_value Add(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    int32_t a = 0, b = 0;
    napi_get_value_int32(env, argv[0], &a);
    napi_get_value_int32(env, argv[1], &b);

    bool ok = false;
    std::string res = GoAdd(a, b, &ok);
    napi_value out = nullptr;
    napi_create_string_utf8(env, res.c_str(), res.length(), &out);
    return out;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) {
    napi_module_register(&demoModule);
}
