( function _RemoteRequireClient_s_() {

  'use strict';

  //

  var _global_ = window;
  var Self = function wRemoteRequireClient( o )
  {
    return Self.prototype.init.apply( this,arguments );
  }

  //

  function init( o )
  {
    var self = this;

    // debugger
    // _.assert( arguments.length === 0 | arguments.length === 1 );

    Object.assign( self,Self.prototype.Fields );

    if( o )
    Object.assign( self,o );

    if( !self.remoteAdress )
    // self.remoteAdress = 'http://localhost:3333';
    self.remoteAdress = window.location.href;

    self._requestUrl = new URL( 'require', self.remoteAdress ).href;

    _global_[ self.nameShort ] = self;
  }

  //

  function require( src )
  {
    var self = this;

    // console.log( "require:", src, "from token:", self.token );

    var urlBase = new URL( 'require?package='+src, window.location.href ).href;
    var url;

    if( self.local )
    {
      url =  urlBase+'&local=1';
    }
    else
    {
      url =  urlBase+'&token='+self.token;
    }

    var advanced  =
    {
      send : null,
      method : 'GET',
      user : null,
      password : null,
    };
    var responseData = Self.get({ filePath : url, advanced : advanced, sync : 1 });

    var data = JSON.parse( responseData );
    if( data.fail )
    {
      throw new Error( 'Can not require: ' + src )
      return;
    }

    // debugger
    if( wRemoteRequire.exports[ data.token ] )
    {
      return wRemoteRequire.exports[ data.token ];
    }

    if( self.token )
    {
      if( !wRemoteRequire.parents[ self.token ] )
      wRemoteRequire.parents[ self.token ] = [];

      wRemoteRequire.parents[ self.token ].push( data.token );
    }

    var exports = {};
    wRemoteRequire.exports[ data.token ] = exports;

    var imported = document.createElement('script');
    imported.type = "text/javascript";
    imported.token = data.token;
    imported.tokenParent = self.token;
    imported.filePath = data.filePath;
    imported.defer = true;
    imported.async = false;
    imported.appendChild( document.createTextNode( data.code ) )

    if( self.script )
    document.head.insertBefore( imported, self.script );
    else
    document.head.appendChild(imported);


    return exports;
  }

  //

  function resolve( src )
  {
    var self = this;

    // debugger

    var url = new URL( 'resolve?package='+src+'&fromInclude=1', window.location.href ).href;

    var advanced  =
    {
      send : null,
      method : 'GET',
      user : null,
      password : null,
    };
    var responseData = Self.get({ filePath : url, advanced : advanced, sync : 1 });

    var data = JSON.parse( responseData );
    if( data.fail )
    throw new Error( "Can't resolve " + src );

    return data.filePath;
  }

  //

  function _setup()
  {
    function _moduleGet()
    {
      var self = document.currentScript;

      if( !self.module )
      self.module =
      {
        exports : Self.exports[ self.token ],
        parent : Self.parents[ self.tokenParent ],
        isBrowser : true
      };

      return self.module;
    }

    function _requireGet()
    {
      let self = document.currentScript;

      if( !self.require )
      {
        self.require = require.bind
        ({
          token : self.token,
          script : self
        });
        self.require.resolve = resolve.bind( self );
      }


      return self.require;
    }

    Object.defineProperty( _global_, 'module', { get: _moduleGet } );
    Object.defineProperty( _global_, 'require', { get: _requireGet } );
  }

  //

  function get( o )
{
  var self = this;
  // debugger
  var Reqeust,request,total,result;

  // _.assertRoutineOptions( fileReadAct,arguments );
  // _.assert( arguments.length === 1, 'expects single argument' );
  // _.assert( _.strIs( o.filePath ),'fileReadAct :','expects {-o.filePath-}' );
  // _.assert( _.strIs( o.encoding ),'fileReadAct :','expects {-o.encoding-}' );
  // _.assert( !o.sync,'fileReadAct :','synchronous version is not implemented' );

  // o.encoding = o.encoding.toLowerCase();
  // var encoder = fileReadAct.encoders[ o.encoding ];

  // advanced

  if( !o.advanced )
  o.advanced =
  {
    send : null,
    method : 'GET',
    user : null,
    password : null
  }

  // _.mapComplement( o.advanced,fileReadAct.advanced );
  // _.assertMapHasOnly( o.advanced,fileReadAct.advanced );

  o.advanced.method = o.advanced.method.toUpperCase();

  // http request

  if( typeof XMLHttpRequest !== 'undefined' )
  Reqeust = XMLHttpRequest;
  else if( typeof ActiveXObject !== 'undefined' )
  Reqeust = new ActiveXObject( 'Microsoft.XMLHTTP' );
  else
  {
    throw new Error( 'not implemented' );
  }

  /* handler */

  function getData( response )
  {
    if( request.responseType === 'text' )
    return response.responseText || response.response;
    if( request.responseType === 'document' )
    return response.responseXML || response.response;
    return response.response;
  }

  /* end */

  function handleEnd( e )
  {

    if( o.ended )
    return;

    result = getData( request );

    // let context = { data : result, operation : o, encoder : encoder };
    // result = context.data

    o.ended = 1;
  }

  /* error event */

  function handleErrorEvent( e )
  {
    throw new Error( e );
  }

  /* state */

  function handleState( e )
  {

    if( o.ended )
    return;

    if( this.readyState === 2 )
    {

    }
    else if( this.readyState === 3 )
    {

      var data = getData( this );
      if( !data ) return;
      if( !total ) total = this.getResponseHeader( 'Content-Length' );
      total = Number( total ) || 1;
      if( isNaN( total ) ) return;
      // handleProgress( data.length / total,o );

    }
    else if( this.readyState === 4 )
    {

      if( o.ended )
      return;

      /*if( this.status === 200 || this.status === 0 )*/
      if( this.status === 200 )
      {

        handleEnd( e );

      }
      else if( this.status === 0 )
      {
      }
      else
      {
        throw new Error( '#' + this.status );
      }

    }

  }

  /* set */

  request = o.request = new Reqeust();

  if( !o.sync )
  request.responseType = 'text';

  // request.addEventListener( 'progress', handleProgress );
  request.addEventListener( 'load', handleEnd );
  request.addEventListener( 'error', handleErrorEvent );
  request.addEventListener( 'timeout', handleErrorEvent );
  request.addEventListener( 'readystatechange', handleState );
  request.open( o.advanced.method, o.filePath, !o.sync, o.advanced.user, o.advanced.password );
  /*request.setRequestHeader( 'Content-type','application/octet-stream' );*/

  if( o.advanced && o.advanced.send !== null )
  request.send( o.advanced.send );
  else
  request.send();

  return result;
}

get.defaults =
{
  sync : null,
  filePath : null,
  encoding : null,
  advanced : null,
}

get.advanced =
{
  send : null,
  method : 'GET',
  user : null,
  password : null,
}

  //

  // --
  // relationship
  // --

  var Fields =
  {
    remoteAdress : null,
    verbosity : 1,
    _requestUrl : null,
    nameShort : 'RemoteRequire'
  }

  var Statics =
  {
    exports : Object.create( null ),
    parents : Object.create( null ),
    setup : _setup,
    get : get
  }

  var Proto =
  {
    init : init,

    require : require,
    resolve : resolve,

    requireLocal : require.bind({ local : 1 }),

    Fields : Fields
  }

  //

  for( let r in Proto )
  Self.prototype[ r ] = Proto[ r ];

  for( let r in Statics )
  Self[ r ] = Statics[ r ];

  _global_.wRemoteRequire = Self;

  Self.setup();

})();