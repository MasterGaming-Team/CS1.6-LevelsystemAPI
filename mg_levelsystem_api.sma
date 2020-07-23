#include <amxmodx>
#include <amxmisc>
#include <mg_regsystem_api>
#include <sqlx>

#define PLUGIN "[MG] Levelsystem API"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

new Handle:gSqlLevelTuple

new bool:gLevelsLoaded[33]
new gUserLevel[33]
new gUserExp[33]

new gForwardClientLevelUp

new retValue

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    gForwardClientLevelUp = CreateMultiForward("mg_fw_client_levelup", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
}

public plugin_natives()
{
    gSqlLevelTuple = SQL_MakeDbTuple("127.0.0.1", "MG_User", "fKj4zbI0wxwPoFzU", "cs_global")

    register_native("mg_level_client_level_get", "native_client_level_get")
    
    register_native("mg_level_client_exp_set", "native_client_exp_set")
    register_native("mg_level_client_exp_get", "native_client_exp_get")
    register_native("mg_level_client_exp_add", "native_client_exp_add")
}

public sqlLoadLevelHandle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    new id = data[0]
    new accountId = data[1]

    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        gLevelsLoaded[id] = false
        log_amx("%s", error)
        mg_reg_user_sqlload_finished(id, MG_SQLID_LEVEL)
        return
	}

    if(!SQL_NumResults(Query))
    {
        userAddLevel(id, accountId)
        return
    }

    gUserLevel[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "accountLevel"))
    gUserExp[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "accountExp"))

    gLevelsLoaded[id] = true
    mg_reg_user_sqlload_finished(id, MG_SQLID_LEVEL)
}

public sqlAddLevelHandle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    new id = data[0]

    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        gLevelsLoaded[id] = false
        log_amx("%s", error)
        mg_reg_user_sqlload_finished(id, MG_SQLID_LEVEL)
        return
	}

    mg_fw_client_clean(id)
    gLevelsLoaded[id] = true
    mg_reg_user_sqlload_finished(id, MG_SQLID_LEVEL)
}

public sqlUpdateLevelHandle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        return
	}
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

public mg_fw_client_login_process(id, accountId)
{
    userLoadLevel(id, accountId)

    mg_reg_user_sqlload_start(id, MG_SQLID_LEVEL)
    return PLUGIN_HANDLED
}

public mg_fw_client_clean(id)
{
    gLevelsLoaded[id] = false
    gUserLevel[id] = 0
    gUserExp[id] = 0
}

public mg_fw_client_sql_save(id, accountId)
{
    if(!gLevelsLoaded[id])
        return
    
    new lSqlTxt[250]
	
    formatex(lSqlTxt, charsmax(lSqlTxt), "UPDATE accountStatus SET accountLevel = ^"%d^", accountExp = ^"%d^" WHERE accountId=^"%d^";", gUserLevel[id], gUserExp[id], accountId)
    SQL_ThreadQuery(gSqlLevelTuple, "sqlUpdateLevelHandle", lSqlTxt)
}

userLoadLevel(id, accountId)
{
    if(!is_user_connected(id))
        return false

    new lSqlTxt[250], data[2]
	
    data[0] = id
    data[1] = accountId
	
    formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT accountLevel, accountExp FROM accountStatus WHERE accountId=^"%d^";", accountId)
    SQL_ThreadQuery(gSqlLevelTuple, "sqlLoadLevelHandle", lSqlTxt, data, 2)
	
    return true
}

userAddLevel(id, accountId)
{
    if(!is_user_connected(id))
        return false

    new lSqlTxt[250], data[1]
	
    data[0] = id
	
    formatex(lSqlTxt, charsmax(lSqlTxt), "INSERT INTO accountStatus (`accountId`) VALUE ^"%d^";", accountId)
    SQL_ThreadQuery(gSqlLevelTuple, "sqlAddLevelHandle", lSqlTxt, data, 1)
	
    return true
}

checkUserLevel(id)
{
    new lNeededExp

    while(gUserExp[id] >= (lNeededExp = getUserNeededExp(id)))
    {
        userLevelUp(id, gUserExp[id] - lNeededExp)
    }
}

getUserNeededExp(id)
{
    return getLevelNeededExp(gUserLevel[id]+1)
}

getLevelNeededExp(level)
{
    return (15*level*(1+level))-(12*(level-1)*level)
}

userLevelUp(id, extraExp = 0)
{
    gUserLevel[id]++
    gUserExp[id] = extraExp

    ExecuteForward(gForwardClientLevelUp, retValue, id, gUserLevel[id], gUserExp[id])
}