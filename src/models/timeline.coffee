db = require('./db')

TimelineSchema = new db.Schema {
  Name      : String
  Mobile    : String
  AddTime   : Number
  Type      : String
  PiwikData : {}
  Location  : {}
}

module.exports = db.Scrm.model 'Timeline', TimelineSchema, 'tb_module_scrm_logs'