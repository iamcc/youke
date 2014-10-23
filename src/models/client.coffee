db = require('./db')

ClientSchema = new db.Schema {
  TID          : db.Types.ObjectId
  OpenId       : String
  Name         : String
  Sex          : Number
  RealSex      : Number
  Mobile       : String
  FaceImageUrl : String
  Contacts : [{
    Name   : String
    Mobile : String
  }]
  Tags       : [String]
  Tags2      : [String]
  AllSaleses : [db.Types.ObjectId]
  Sales      : db.Types.ObjectId
  Status     : type: String, enum: ['未报备', '已报备', '跟进中', '已签约', '无效客户'], default: '未报备'
  Memo       : String
}

module.exports = db.Scrm.model 'Client', ClientSchema, 'tb_module_scrm_member'