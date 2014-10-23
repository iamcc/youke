db = require './db'

TenantSchema = new db.Schema {
  TID      : db.Types.ObjectId
  ModuleID : Number
  Config   : {}
}

module.exports = db.Tenant.model 'Tenant', TenantSchema, 'tb_tenant_module'
