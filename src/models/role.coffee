db = require './db'

RoleSchema = new db.Schema {
  tid        : type: db.Types.ObjectId, required: true, index: true
  name       : type: String, required: true
  mark       : String
  saleses    : [{type: db.Types.ObjectId, ref: 'Sales'}]
  permission :
    onlineSales : Boolean
    pickClient  :
      checked   : Boolean
      numPerDay : type: Number, default: 0
      wbbDays   : type: Number, default: 15
      ybbDays   : type: Number, default: 15
      gjzDays   : type: Number, default: 15
    assignClient :
      checked : Boolean
      protect : Boolean
    shareClient : Boolean
  createdAt  : type: Date, default: Date.now
  updatedAt  : type: Date, default: Date.now
}

RoleSchema.index {tid: 1, name: 1}, {unique: true}

module.exports = db.Youke.model 'Role', RoleSchema, 'roles'