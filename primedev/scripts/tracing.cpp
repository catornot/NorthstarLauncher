#include "tracing.h"
#include "squirrel/squirrel.h"
#include "tracy/Tracy.hpp"
#include "vscript/languages/squirrel_re/include/squirrel.h"
#include "vscript/languages/squirrel_re/squirrel/sqobject.h"
#include <common/TracyColor.hpp>
#include <cstddef>
#include <cstdint>
#include <cstring>

static uint64_t(__fastcall* o_pHSquirrelVMExecute)(HSQUIRRELVM* sqvm, uint64_t * closure, uint32_t nargs, uint32_t stackbase, SQObject * outres, int raiseerror, uint32_t et) = nullptr;
static uint64_t __fastcall h_pHSquirrelVMExecute(HSQUIRRELVM* sqvm, uint64_t * closure, uint32_t nargs, uint32_t stackbase, SQObject * outres, int raiseerror, uint32_t et)
{
	ZoneScoped;
	ZoneColor( tracy::Color::Red3 );

	const char * name = "unkown squirrel function";
	size_t size = strlen(name);
	if (closure) {
		SQObject obj = *reinterpret_cast< SQObject *>(closure);
		SQObject proto;

		switch (obj._Type) {
				case OT_CLOSURE:
						proto = obj._VAL.asClosure->_function;
						if (proto._Type == OT_FUNCPROTO && proto._VAL.asFuncProto->_funcName) {
							name = proto._VAL.asFuncProto->_funcName->_val;
							size = proto._VAL.asFuncProto->_funcName->length;
						}
						break;
				case OT_FUNCPROTO:
					if (obj._VAL.asFuncProto->_funcName) {
						name = obj._VAL.asFuncProto->_funcName->_val;
						size = obj._VAL.asFuncProto->_funcName->length;
					}
					break;
				case OT_NATIVECLOSURE:
					if (obj._VAL.asNativeClosure->_name) {
						name = obj._VAL.asNativeClosure->_name->_val;
						size = obj._VAL.asNativeClosure->_name->length;
					}
					break;
				case _RT_NULL:
					name = "_RT_NULL";
					size = strlen(name);
					break;
				case _RT_INTEGER:
					name = "_RT_INTEGER";
					size = strlen(name);
					break;
				case _RT_FLOAT:
					name = "_RT_FLOAT";
					size = strlen(name);
					break;
				case _RT_BOOL:
					name = "_RT_BOOL";
					size = strlen(name);
					break;
				case _RT_STRING:
					name = "_RT_STRING";
					size = strlen(name);
					break;
				case _RT_TABLE:
					name = "_RT_TABLE";
					size = strlen(name);
					break;
				case _RT_ARRAY:
					name = "_RT_ARRAY";
					size = strlen(name);
					break;
				case _RT_USERDATA:
					name = "_RT_USERDATA";
					size = strlen(name);
					break;
				case _RT_CLOSURE:
					name = "_RT_CLOSURE";
					size = strlen(name);
					break;
				case _RT_NATIVECLOSURE:
					name = "_RT_NATIVECLOSURE";
					size = strlen(name);
					break;
				case _RT_GENERATOR:
					name = "_RT_GENERATOR";
					size = strlen(name);
					break;
				case OT_USERPOINTER:
					name = "OT_USERPOINTER";
					size = strlen(name);
					break;
				case _RT_THREAD:
					name = "_RT_THREAD";
					size = strlen(name);
					break;
				case _RT_FUNCPROTO:
					name = "_RT_FUNCPROTO";
					size = strlen(name);
					break;
				case _RT_CLASS:
					name = "_RT_CLASS";
					size = strlen(name);
					break;
				case _RT_INSTANCE:
					name = "_RT_INSTANCE";
					size = strlen(name);
					break;
				case _RT_WEAKREF:
					name = "_RT_WEAKREF";
					size = strlen(name);
					break;
				case OT_VECTOR:
					name = "OT_VECTOR";
					size = strlen(name);
					break;
				case SQOBJECT_CANBEFALSE:
					name = "SQOBJECT_CANBEFALSE";
					size = strlen(name);
					break;
				case OT_NULL:
					name = "OT_NULL";
					size = strlen(name);
					break;
				case OT_BOOL:
					name = "OT_BOOL";
					size = strlen(name);
					break;
				case SQOBJECT_DELEGABLE:
					name = "SQOBJECT_DELEGABLE";
					size = strlen(name);
					break;
				case SQOBJECT_NUMERIC:
					name = "SQOBJECT_NUMERIC";
					size = strlen(name);
					break;
				case OT_INTEGER:
					name = "OT_INTEGER";
					size = strlen(name);
					break;
				case OT_FLOAT:
					name = "OT_FLOAT";
					size = strlen(name);
					break;
				case SQOBJECT_REF_COUNTED:
					name = "SQOBJECT_REF_COUNTED";
					size = strlen(name);
					break;
				case OT_STRING:
					name = "OT_STRING";
					size = strlen(name);
					break;
				case OT_ARRAY:
					name = "OT_ARRAY";
					size = strlen(name);
					break;
				case OT_ASSET:
					name = "OT_ASSET";
					size = strlen(name);
					break;
				case OT_THREAD:
					name = "OT_THREAD";
					size = strlen(name);
					break;
				case OT_CLAAS:
					name = "OT_CLAAS";
					size = strlen(name);
					break;
				case OT_STRUCT:
					name = "OT_STRUCT";
					size = strlen(name);
					break;
				case OT_WEAKREF:
					name = "OT_WEAKREF";
					size = strlen(name);
					break;
				case OT_TABLE:
					name = "OT_TABLE";
					size = strlen(name);
					break;
				case OT_USERDATA:
					name = "OT_USERDATA";
					size = strlen(name);
					break;
				case OT_INSTANCE:
					name = "OT_INSTANCE";
					size = strlen(name);
					break;
				case OT_ENTITY:
					name = "OT_ENTITY";
					size = strlen(name);
					break;
				default:
					name = SQTypeNameFromID(obj._Type);
					size = strlen(name);
					break;
				}
	}

	ZoneName(name, size);

	return o_pHSquirrelVMExecute(sqvm, closure, nargs, stackbase, outres, raiseerror, et);
}

ON_DLL_LOAD("server.dll", ScriptsTracing, (CModule module))
{
	o_pHSquirrelVMExecute = module.Offset(0x02f950).RCast<decltype(o_pHSquirrelVMExecute)>();
	HookAttach(&(PVOID&)o_pHSquirrelVMExecute, (PVOID)h_pHSquirrelVMExecute);
}
