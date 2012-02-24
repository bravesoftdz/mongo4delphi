{***************************************************************************}
{                                                                           }
{                    Mongo Delphi Driver                                    }
{                                                                           }
{           Copyright (c) 2012 Fabricio Colombo                             }
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}
unit Mongo;

interface

uses Sockets, MongoEncoder, MongoDecoder, BSONStream, BSONTypes, MongoProvider;

const
  DEFAULT_HOST = 'localhost';
  DEFAULT_PORT = 27017;

type
  TMongoDB = class;
  TMongoCollection = class;

  TMongo = class
  private
    FProvider: IMongoProvider;
    FEncoder: IMongoEncoder;
    FDecoder: IMongoDecoder;
    procedure SetEncoder(const Value: IMongoEncoder);
    procedure SetDecoder(const Value: IMongoDecoder);
  public
    constructor Create;
    destructor Destroy; override;

    property Encoder: IMongoEncoder read FEncoder write SetEncoder;
    property Decoder: IMongoDecoder read FDecoder write SetDecoder; 

    procedure Open(AHost: String = DEFAULT_HOST; APort: Integer = DEFAULT_PORT);

    function getDB(const ADBname: String): TMongoDB;
  end;

  TMongoDB = class
  private
    FMongo: TMongo;
    FDBName: String;
  public
    constructor Create(AMongo: TMongo; ADBName: String);
    destructor Destroy; override;

    property DBName: String read FDBName;

//    function RunCommand(ACommand: IBSONDocument): IBSONDocument;

    function GetCollection(AName: String): TMongoCollection;
    procedure DropCollection(AName: String);
  end;

  TMongoCollection = class
  private
    FMongoDatabase: TMongoDB;
    FCollectionName: String;

    function GetFullName: String;

    //function GenerateIndexName(KeyFields: IBSONDocument): String;
  public
    constructor Create(AMongoDatabase: TMongoDB; AName: String);

    property CollectionName: String read FCollectionName;
    property FullName: String read GetFullName;

    
    (*
    function Count(Query: IBSONDocument = nil; Limit: Integer = 0): Integer;

    function Find(Query: IBSONDocument = nil): IMongoDBCursor;

    function CreateIndex(KeyFields: IBSONDocument; AIndexName: String = ''): IBSONDocument;
    function DropIndex(AIndexName: String): Boolean;
    *)
    procedure Insert(const BSONObject: IBSONObject);

    function FindOne(Query: IBSONObject): IBSONObject;

    //TODO Map/Reduce
    //TODO remove
    //TODO update

  end;

 IMongoDBCursor = interface
  ['{7204C1E4-ABAC-4DC3-9CBA-76DFCCCB59B2}']
(*
    function Count: Integer;
    function Size: Integer;
    function Sort(AOrder: IBSONDocument): IMongoDBCursor;
    //TODO function Hint(AIndexKeys: IBSONDocument): IMongoDBCursor;overload;
    //TODO function Hint(AIndexName: String): IMongoDBCursor;overload;
    function Snapshot: IMongoDBCursor;
    function Explain: IBSONDocument;
    function Limit(n: Integer): IMongoDBCursor;
    function Skip(n: Integer): IMongoDBCursor;
    function BatchSize(n: Integer): IMongoDBCursor;

    function HasNext: Boolean;
    function Next: IBSONDocument;  *)
  end;

  //TODO Make implement an interface to release object
  TMongoDBCursor = class(TInterfacedObject, IMongoDBCursor)
  private
  (*
    FCollection: TMongoCollection;
    FQuery: IBSONDocument;
    FFields: IBSONDocument;
    FWireQuery: TMongoWireQuery;
    FBatchSize: Integer;
    FLimit: Integer;
    FSkip: Integer;
    FOrderBy: IBSONDocument;
    FExplain: Boolean;
    FSnapShot: Boolean;

    procedure OpenCursor;

    procedure AssertCursorIsNotOpen;

    function ChooseBatchSize(batchSize, limit, fetched: Integer): Integer;

    function Clone: TMongoDBCursor;
  public
    constructor Create(ACollection: TMongoCollection; AQuery: IBSONDocument; AFields: IBSONDocument);
    destructor Destroy; override;

    function Count: Integer;
    function Size: Integer;
    function Sort(AOrder: IBSONDocument): IMongoDBCursor;
    //TODO function Hint(AIndexKeys: IBSONDocument): IMongoDBCursor;overload;
    //TODO function Hint(AIndexName: String): IMongoDBCursor;overload;
    function Snapshot: IMongoDBCursor;
    function Explain: IBSONDocument;
    function Limit(n: Integer): IMongoDBCursor;
    function Skip(n: Integer): IMongoDBCursor;
    function BatchSize(n: Integer): IMongoDBCursor;

    function HasNext: Boolean;
    function Next: IBSONDocument;
    *)
  end;

implementation

uses SysUtils, MongoException, BSON, Classes;

{ TMongo }

constructor TMongo.Create;
begin
  FProvider := TDefaultMongoProvider.Create;
  SetEncoder(TMongoEncoderFactory.DefaultEncoder);
  SetDecoder(TMongoDecoderFactory.DefaultDecoder);
end;

destructor TMongo.Destroy;
begin
  inherited;
end;

function TMongo.getDB(const ADBname: String): TMongoDB;
begin
  Result := TMongoDB.Create(Self, ADBname);
end;

procedure TMongo.Open(AHost: String; APort: Integer);
begin
  FProvider.Open(AHost, APort);
end;

procedure TMongo.SetDecoder(const Value: IMongoDecoder);
begin
  FDecoder := Value;
  FProvider.SetDecoder(FDecoder);
end;

procedure TMongo.SetEncoder(const Value: IMongoEncoder);
begin
  FEncoder := Value;
  FProvider.SetEncoder(FEncoder);
end;

{ TMongoDB }

constructor TMongoDB.Create(AMongo: TMongo; ADBName: String);
begin
  FMongo := AMongo;
  FDBName := ADBName;
end;

destructor TMongoDB.Destroy;
begin

  inherited;
end;

procedure TMongoDB.DropCollection(AName: String);
begin

end;

function TMongoDB.GetCollection(AName: String): TMongoCollection;
begin
  Result := TMongoCollection.Create(Self, AName);
end;

{ TMongoCollection }

constructor TMongoCollection.Create(AMongoDatabase: TMongoDB; AName: String);
begin
  FMongoDatabase := AMongoDatabase;
  FCollectionName := AName;
end;

function TMongoCollection.FindOne(Query: IBSONObject): IBSONObject;
begin
  Result := FMongoDatabase.FMongo.FProvider.FindOne(FMongoDatabase.DBName, FCollectionName, Query);
end;

function TMongoCollection.GetFullName: String;
begin
  Result := FMongoDatabase.DBName + '.' + FCollectionName;
end;

procedure TMongoCollection.Insert(const BSONObject: IBSONObject);
begin
  FMongoDatabase.FMongo.FProvider.Insert(FMongoDatabase.DBName, FCollectionName, BSONObject);
end;

end.