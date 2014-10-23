(function($, pomelo, Handlebars, console, undefined) {
  var saleses = [];
  var tpl = {
    userlist: Handlebars.compile($('#user-list-tpl').html()),
    msg: Handlebars.compile($('#msg-tpl').html())
  };
  // var host = '127.0.0.1';
  var host = 'dev.youke.aimapp.net';
  var token, me;

  var getParams = function() {
    var params = {};
    location.search.slice(1).split('&').forEach(function(param) {
      param = param.split('=');
      params[param[0]] = param[1];
    });
    token = params.token;
  };

  var getSaleses = function() {
    if(!token) return console.log("token empty");

    $.getJSON('/api/public/saleses?token='+token, initUsers);
  };

  var initUsers = function(data) {
    saleses = data.saleses;
    me = data.user;
    renderUserList();
    $('#user-list').on('click', '.media', clickUser);
  };

  var renderUserList = function() {
    if(!!me.sid) {
      for(var i in saleses) {
        var s = saleses[i];
        if(s._id == me.sid) {
          saleses.splice(i, 1);
          saleses.splice(0, 0, s);
        } else {
          s.disabled = true;
        }
      }
    }
    $('#user-list').html(tpl.userlist(saleses));
  };

  var clickUser = function() {
    toId = $(this).data('id');
    if(me.sid && me.sid != toId) return;
    queryEntry(entry);
    $('title').html('chat to ' + $(this).data('name'));
    $('#user-list').hide();
    $('#chat-box').show();
  };

  var queryEntry = function(cb) {
    pomelo.init({
      host: host,
      port: 3199,
      log: true
    }, function() {
      pomelo.request('gate.gateHandler.queryEntry', {
        token: token
      }, function(data) {
        pomelo.disconnect();

        if (data.code === 200) {
          cb(data.host, data.port);
        } else {
          console.debug(data);
        }
      });
    });
  };

  var entry = function(host, port) {
    pomelo.init({
      host: host,
      port: port,
      log: true
    }, function() {
      var route = 'connector.entryHandler.entry';
      var param = {
        token: token
      };
      pomelo.request(route, param, function(data) {
        if(data.code === 200) {
          getOfflineMessages();
        } else {
          document.write(data.code);
          console.debug(data);
        }
      });
    });
  };

  var getOfflineMessages = function() {
    pomelo.request(
      'chat.chatHandler.getOfflineMessages',
      {},
      function(data) {
        if(data.code === 200) {
          var ids = data.msgs.map(function(m) {return m._id;});
          data.msgs.forEach(function(msg) {
            if(msg.uid == toId) {
              appendMsg(msg);
            }
          });
          receive(ids);
        } else {
          console.error(data);
        }
      }
    );
  };

  var receive = function(id) {
    pomelo.request(
      'chat.chatHandler.receive',
      {id: id},
      function(data) {
        console.log('received', data);
      }
    );
  };

  var sendMsg = function(msg, cb) {
    if (!toId) return console.debug('toId is empty');
    if (!msg) return console.debug('msg is empty');
    var route = 'chat.chatHandler.send';
    var param = {
      to: toId,
      msg: msg,
    };
    var $msg = appendMsg({uid: me._id, msg: '[sending] '+msg});
    var $box = $('#chat-box');
    $box.scrollTop($box[0].scrollHeight);
    pomelo.request(route, param, function(data) {
      $msg.attr('id', 'msg'+data.id);
      $msg.find('.msg-body').html(msg);
      console.debug("send msg", data);
    });
  };

  var appendMsg = function(msg) {
    if(Array.isArray(msg)) {
      msg.forEach(function(m) {
        appendMsg(m);
      });
    } else {
      msg.isMe = msg.uid == me._id;
      msg.avatar = msg.isMe ? me.avatar : $('#sales'+msg.uid+' .media-object').attr('src')
      var $li = $(tpl.msg(msg));
      $('#msg-list').append($li);
      return $li;
    }
  };

  var onDisconnect = function() {
    console.log("disconnected");
  };
  var onChat = function(msg) {
    // debug for app
    if(me.role) {
      toId = msg.uid;
    }
    // end
    if(toId == msg.uid) appendMsg(msg);
    receive(msg.id);
  };
  var onAskContact = function(sid) {
    var sales = $('#sales'+sid);
    $('#contactModal .modal-title').html(sales.data('name')+' 向您索取名片');
    $('#contactModal').modal('show');
  };
  var submitContact = function() {
    var name = $('#txtName').val().trim();
    var mobile = $('#txtMobile').val().trim();
    if(!(name && mobile)) return $('#contactModal .errMsg').html('请填写完整').show();
    pomelo.request(
      'chat.chatHandler.submitContact',
      {uid: me._id, name: name, mobile: mobile},
      function(data) {
        if(data.code === 200) {
          $('#contactModal').modal('hide');
          $('#txtName, #txtMobile').val('');
          $('#contactModal .errMsg').empty().hide();
        } else {
          $('#contactModal .errMsg').html('提交失败').show();
        }
      }
    );
  };
  var rejectContact = function() {
    pomelo.request(
      'chat.chatHandler.rejectContact',
      {uid: me._id},
      function(data) {
        console.log(data);
      }
    );
  };

  $(function() {
    getParams();
    getSaleses();

    pomelo.on('disconnect', onDisconnect);
    pomelo.on('chat', onChat);
    pomelo.on('askContact', onAskContact);

    $('#contactModal .submit').click(submitContact);
    $('#contactModal .reject').click(rejectContact);

    $('#txtMsg').keyup(function(e) {
      if(e.keyCode === 13) $('#btnSend').click();
    });

    $('#btnSend').click(function() {
      var msg = $('#txtMsg').val().trim();
      $('#txtMsg').val('');
      sendMsg(msg);
    });
  });
}($, pomelo, Handlebars, console));