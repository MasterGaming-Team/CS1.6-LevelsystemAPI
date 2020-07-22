#include <amxmodx>
#include <amxmisc>
#include <mg_regsystem_api>

#define PLUGIN "[MG] Levelsystem API"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

new gUserLevel[33]
new gUserExp[33]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_natives()
{
    register_native("mg_level_client_level_get", "native_client_level_get")

    register_native("mg_level_client_exp_set", "native_client_exp_set")
    register_native("mg_level_client_exp_get", "native_client_exp_get")
    register_native("mg_level_client_exp_add", "native_client_exp_add")
}

public native_client_level_get(plugin_id, param_num)
{
    new id = get_param(id)

    if(!mg_reg_user_loggedin(id))
        return 0
    
    return gUserLevel[id]
}

public native_client_exp_set(plugin_id, param_num)
{
    new id = get_param(1)

    if(!mg_reg_user_loggedin(id))
        return
    
    new lExp = get_param(2)
    
    gUserExp[id] = lExp
    checkUserLevel(id)
}

public native_client_exp_get(plugin_id, param_num)
{
    new id = get_param(1)

    if(!mg_reg_user_loggedin(id))
        return 0
    
    return gUserExp[id]
}

public native_client_exp_add(plugin_id, param_num)
{
    new id = get_param(1)

    if(!mg_reg_user_loggedin(id))
        return 0
    
    new lExp = get_param(2)

    gUserExp[id] += lExp
    checkUserLevel(id)

    return gUserExp[id]
}

checkUserLevel(id)
{
    // Még kikéne találni a szintlépés rendszerét
}