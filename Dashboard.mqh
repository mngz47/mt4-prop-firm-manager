//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict


enum RISK_MODE
  {
   dollar,//$
   percent//%
  };

enum TIME_MODE
  {
   local,//Local time
   server//Server time
  };

enum CLOSE_TYPE
  {
   all,//Close all
   selected//Close selected magic number
  };

enum DD_MODE
  {
   pertrade,//Maximum loss per trade
   overall//Maximum daily drawdown
  };

enum RESTART_DAY
  {
   sunday,//Sunday
   monday//Monday
  };

enum DISABLE_REASON
  {

   none,
   drawdown,
   night,
   weekend,
   news

  };

DD_MODE InpDDMode         = overall;//Loss management mode
double InpMaxLossPerTrade = 20;//Maximum loss per trade ($)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string InpSep1            = "";//================DRAWDOWN==========================
double InpMaxDailyDD      = 4;//Maximum daily drawdown (%)
string InpResetTime       = "00:00";//Daily drawdown reset time (UTC)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string InpSep2            = "";//================OVERNIGHT TRADING==========================
bool   InpAllowOvernight     = false;//Allow overnight trading?
string InpTradingHours       = "08:00-17:00";//Trading Hours (UTC)

string InpSep3           = "";//================WEEKEND TRADING==========================
bool   InpWeekendTrading     = false;//Allow weekend trading?
string InpFridayShutdownTime = "18:00";//Friday shutdown time (UTC)
RESTART_DAY InpRestartDay    = monday;//New week starts on?

string InpSep4           = "";//================NEWS TRADING==========================
bool     InpTradeNews   = false;//Trade during news?
bool     InpHighImpact  = true;//Filter high impact news
bool     InpMediumImpact  = false;//Filter medium impact news
bool     InpLowImpact  = false;//Filter low impact news
bool     InpShowNews    = true;//Display news lineup on chart
int      InpPreNewsShutdownTime = 15;//Stop trading X mins before news
int      InpPostNewsResumeTime  = 15;//Resume trading X mins after news
bool     InpCloseMarket         = true;//Close open trades before news
bool     InpClosePending        = true;//Close pending orders before news
double   InpInitAccSize         = 50000;

DISABLE_REASON DisableReason;

string TradeStartTime;
string TradeStopTime;

int XOffset;
int YOffset;

bool FridayOff;

double InpMaxLoss         = 100;//Maximum overall drawdown ($)

double StartingBalance;

string newsinfo = "";

string NewsItems[];

string file_url = "https://nfs.faireconomy.media/ff_calendar_thisweek.csv";

double InpMaxProfit      = 20;//Max profit

string InpTradeStartTime = "08:00";//Trade start time
string InpTradeStopTime  = "14:00";//Trade stop time
CLOSE_TYPE InpCloseType  = all;//Choose which EAs to manage
string InpMagicNumbers   = "";//Magic numbers (separate by commas)
bool   InpDisableOnProfit = false;//Disable on profit
bool   InpDisableOnLoss = false;//Disable on loss

string MN[];
long MagicNumbers[];
string News2[];

int NewsPage;

int EAOff;

#include <WinUser32.mqh>
#import "user32.dll"
int GetAncestor(int, int);
#import

#define  MT_WMCMD_EXPERTS 33020

#import "wininet.dll"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InternetOpenW(
   string     sAgent,
   int        lAccessType,
   string     sProxyName="",
   string     sProxyBypass="",
   int     lFlags=0
);
int InternetOpenUrlW(
   int     hInternetSession,
   string     sUrl,
   string     sHeaders="",
   int     lHeadersLength=0,
   int     lFlags=0,
   int     lContext=0
);
int InternetReadFile(
   int     hFile,
   uchar  &   sBuffer[],
   int     lNumBytesToRead,
   int&     lNumberOfBytesRead
);
int InternetCloseHandle(
   int     hInet
);
#import

int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig = 0;
int Internet_Open_Type_Direct = 1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int hSession(bool Direct)
  {
   string InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";

   if(Direct)
     {
      if(hSession_Direct == 0)
        {
         hSession_Direct = InternetOpenW(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
        }

      return(hSession_Direct);
     }
   else
     {
      if(hSession_IEType == 0)
        {
         hSession_IEType = InternetOpenW(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
        }

      return(hSession_IEType);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string httpGET(string strUrl)
  {
   int handler = hSession(false);
   int response = InternetOpenUrlW(handler, strUrl);
   if(response == 0)
      return("");

   uchar ch[100];
   string toStr="";
   int dwBytes, h=-1;
   int retries = 0;

   while(InternetReadFile(response, ch, 100, dwBytes) && retries < 100)
     {
      if(dwBytes<=0)
         break;
      toStr=toStr+CharArrayToString(ch, 0, dwBytes);
      retries++;
     }

   InternetCloseHandle(response);
   return toStr;
  }

int TimezoneOffsetSecs;
int NewsCnt;
bool IsInDrawdown;
bool IsCloseTime;
bool IsWeekend;

color BG;
color FG;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int DOnInit()
  {

   ChartSetInteger(0,CHART_COLOR_BACKGROUND,Black);

   BG = Tan;//(color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
   FG = Black;//(color)ChartGetInteger(0,CHART_COLOR_FOREGROUND);

   XOffset = 75;
   YOffset = -50;

   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrNONE);
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,clrNONE);
   ChartSetInteger(0,CHART_COLOR_ASK,clrNONE);
   ChartSetInteger(0,CHART_COLOR_BID,clrNONE);
   ChartSetInteger(0,CHART_SHOW_OHLC,false);
   ChartSetInteger(0,CHART_SHOW_ASK_LINE,false);
   ChartSetInteger(0,CHART_SHOW_BID_LINE,false);


   if(!IsDllsAllowed())
     {
      MessageBox("Please allow DLL imports for this EA. Go to Tools -> Options -> Expert Advisors");
      return INIT_FAILED;
     }

   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      MessageBox("Please check internet connection and relaunch.");
      return INIT_FAILED;
     }






//CREATE FILE TO SAVE TIME OFFSET FOR THIS TRADE SERVER
   string serverName = AccountInfoString(ACCOUNT_COMPANY);

   if(!FileIsExist(serverName+"_est_timeoffset.txt"))//First time trying to use this EA OR Didn't successfully retrieve UTC time on first try
     {
      string msg = httpGET("https://www.google.com/search?client=avast-a-1&q=get+current+utc+time&oq=get+current+utc+time&aqs=avast..69i57j0l7.8300j0j4&ie=UTF-8");

      //Alert("Time retrieved was ",msg);

      msg = StringSubstr(msg,StringFind(msg,"<span class=\"fYyStc\">"),StringFind(msg,"</span>"));



      msg = StringSubstr(msg,StringFind(msg,":")-2,5);

      if(StringLen(msg) != 5 || StringSubstr(msg,2,1) != ":")
        {
         MessageBox("Failed to retrieve UTC time. ("+(string)GetLastError()+"). Please relaunch.");
         return INIT_FAILED;
        }

      else
        {
         datetime est = StringToTime(msg);
         datetime now = StringToTime(TimeToString(TimeCurrent(),TIME_MINUTES));
         TimezoneOffsetSecs = (int)(now-est);

         int handle5 = FileOpen(serverName+"_timeoffset.txt",FILE_WRITE|FILE_CSV);

         if(handle5==INVALID_HANDLE)
           {
            Print("Server offset handle is invalid");
            return INIT_FAILED;
           }
         else
           {

            FileWrite(handle5,TimezoneOffsetSecs);

            FileClose(handle5);

           }
        }

     }

   else//UTC time was retrieved and saved
     {
      int handle6 = FileOpen(serverName+"_timeoffset.txt",FILE_READ|FILE_CSV);

      if(handle6==INVALID_HANDLE)
        {
         Print("Server offset handle  is invalid");
         return INIT_FAILED;
        }
      else
        {
         TimezoneOffsetSecs = (int)FileReadString(handle6);

         FileClose(handle6);
        }
     }

  // Alert("Time offset is ",GetTZOffset());




// Alert("Current utc time is ",est);

   /*Alert("Current est time is ",est);
   Alert("Current server time is ",TimeCurrent());
   Alert("Current local time is ",TimeLocal());
   Alert("Offset secs = ",TimezoneOffsetSecs);*/


   StringSplit(InpMagicNumbers,StringGetCharacter(",",0),MN);

   for(int i=0; i<ArraySize(MN); i++)
     {
      AddToArray(MagicNumbers,(long)MN[i]);
     }
   NewsPage = 1;

   DisplayNews();
   DisplayDD();
   DisplayNight();
   DisplayWeekend();
   DisplayNewsSettings();
   DisplayMessage();
   DisplayInfo();

   GetInputs();

   string parts[];

   StringSplit(InpTradingHours,StringGetCharacter("-",0),parts);

   if(ArraySize(parts) < 2 || !(StringSubstr(InpTradingHours,2,1)==":" && StringSubstr(InpTradingHours,5,1)=="-"  && StringSubstr(InpTradingHours,8,1)==":"))
     {
      MessageBox("Please set trading hours correctly. Format should be XX:XX-YY:YY");
      return INIT_FAILED;
     }

   FridayOff = false;

   TradeStartTime = parts[0];
   TradeStopTime  = parts[1];

   StringTrimLeft(StringTrimRight(TradeStartTime));
   StringTrimLeft(StringTrimRight(TradeStopTime));



   EventSetTimer(2);
   OnTimer();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i=ObjectsTotal(0,-1,-1)-1; i>=0; i--)
     {
      string name = ObjectName(0,i,-1,-1);

      // if(StringFind(name,"NEWS") >= 0)
      ObjectDelete(0,name);
     }

   int handle = FileOpen("DisableReason.txt",FILE_WRITE|FILE_CSV);

   if(handle==INVALID_HANDLE)
     {
      Print("Handle is invalid");
      return;
     }
   else
     {

      FileWrite(handle,DisableReason);

      FileClose(handle);

     }

   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ResetBalance();

   GetInputs();
   DisplayInfo();

   CheckNews();
   CheckWeekend();
   CheckDrawdown();
   CheckOvernight();

   if(InpWeekendTrading)
     {
      ObjectSetString(0,"MESSAGE_LINE2",OBJPROP_TEXT,"Weekend trading is allowed.");
      ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_COLOR,LightBlue);

      if(NewsCnt==0 && !IsCloseTime && !IsInDrawdown && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
        {
         SetAutoTrading(true);
         Print("Autotrading enabled. ("+__FUNCTION__+")");
         Sleep(5000);
        }
     }

   if(InpTradeNews)
     {
      ObjectSetString(0,"MESSAGE_LINE1",OBJPROP_TEXT,"News trading is allowed.");
      ObjectSetInteger(0,"MESSAGE_LINE1",OBJPROP_COLOR,LightBlue);

      if(IsWeekend == false && !IsInDrawdown && !IsCloseTime && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
        {
         Print("Autotrading enabled. ("+__FUNCTION__+")");
         SetAutoTrading(true);
         Sleep(5000);
        }
     }

   if(InpAllowOvernight)
     {
      ObjectSetString(0,"MESSAGE_LINE3",OBJPROP_TEXT,"Overnight trading allowed.");
      ObjectSetInteger(0,"MESSAGE_LINE3",OBJPROP_COLOR,LightBlue);

      if(IsWeekend == false && NewsCnt==0 && !IsInDrawdown && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
        {
         SetAutoTrading(true);
         Print("Autotrading enabled. ("+__FUNCTION__+")");
         Sleep(5000);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(ObjectGetString(0,sparam,OBJPROP_TEXT)=="NO")
        {
         ObjectSetString(0,sparam,OBJPROP_TEXT,"YES");
         ObjectSetInteger(0,sparam,OBJPROP_BGCOLOR,Green);
        }

      else
         if(ObjectGetString(0,sparam,OBJPROP_TEXT)=="YES")
           {
            ObjectSetString(0,sparam,OBJPROP_TEXT,"NO");
            ObjectSetInteger(0,sparam,OBJPROP_BGCOLOR,Red);
           }

         else
            if(ObjectGetString(0,sparam,OBJPROP_TEXT)=="SUNDAY")
              {
               ObjectSetString(0,sparam,OBJPROP_TEXT,"MONDAY");
               ObjectSetInteger(0,sparam,OBJPROP_BGCOLOR,Teal);
              }

            else
               if(ObjectGetString(0,sparam,OBJPROP_TEXT)=="MONDAY")
                 {
                  ObjectSetString(0,sparam,OBJPROP_TEXT,"SUNDAY");
                  ObjectSetInteger(0,sparam,OBJPROP_BGCOLOR,LightBlue);
                 }
               else
                  if(ObjectGetString(0,sparam,OBJPROP_TEXT)=="PREV")
                    {
                     NewsPage = 1;
                     DisplayNews();
                    }
                  else
                     if(ObjectGetString(0,sparam,OBJPROP_TEXT)=="NEXT")
                       {
                        NewsPage = 2;
                        DisplayNews();
                       }

      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckNews()
  {

   Download();

   if(InpShowNews)
      DisplayNews();

   if(InpTradeNews)
      return;

//NEWS


   int newscnt = 0;

   for(int i=0; i<SymbolsTotal(true); i++)
     {
      string sym = SymbolName(i,true);

      if(IsNews(sym))
        {
         newscnt++;
         // Print(newsinfo);
         // Print(sym," trades are now paused.");
         CloseAll(sym);
        }
     }

   if(newscnt > 0)
     {
      ObjectSetString(0,"MESSAGE_LINE1",OBJPROP_TEXT,"Trading suspended for now. News incoming!");
      ObjectSetInteger(0,"MESSAGE_LINE1",OBJPROP_COLOR,Red);

      NewsCnt = newscnt;

      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == true)
        {
         SetAutoTrading(false);
         DisableReason = news;
         Sleep(5000);
        }



     }
   else
     {

      ObjectSetString(0,"MESSAGE_LINE1",OBJPROP_TEXT,"No scheduled news at the moment.");
      ObjectSetInteger(0,"MESSAGE_LINE1",OBJPROP_COLOR,Lime);

      NewsCnt = 0;

      datetime day = TimeCurrent();

      MqlDateTime t2s;

      TimeToStruct(day,t2s);

      if(IsWeekend == false && !IsInDrawdown && !IsCloseTime && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
        {
         Print("Autotrading enabled. ("+__FUNCTION__+")");
         SetAutoTrading(true);
         Sleep(5000);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckWeekend()
  {

   if(InpWeekendTrading)
      return;

   datetime day = TimeCurrent();

   string d2s = TimeToString(day,TIME_DATE);


//FRIDAY SHUTDOWN
   datetime resetTime = StringToTime(TimeToString(TimeCurrent(),TIME_DATE) + " " + InpResetTime) + TimezoneOffsetSecs;

   MqlDateTime t2s;

   TimeToStruct(day,t2s);

   if((t2s.day_of_week == 5 && TimeCurrent() >= StringToTime(d2s+" "+InpFridayShutdownTime) + TimezoneOffsetSecs) || (InpRestartDay == sunday && t2s.day_of_week == 6) || (InpRestartDay == monday && (t2s.day_of_week == 6 || t2s.day_of_week == 0)))
     {
      IsWeekend = true;

      ObjectSetString(0,"MESSAGE_LINE2",OBJPROP_TEXT,"It's weekend. Friday shutdown is active.");
      ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_COLOR,Red);
      ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_FONTSIZE,8);

      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == true)
        {
         Print("Friday shutdown active. Closing all trades and disabling autotrading...");

         if(CloseTrades())
            SetAutoTrading(false);

         FridayOff = true;
         DisableReason = weekend;
         Sleep(5000);
        }
     }

   else
     {
      if(InpRestartDay == sunday && (t2s.day_of_week == 0 || t2s.day_of_week == 1 || t2s.day_of_week == 2 || t2s.day_of_week == 3 || t2s.day_of_week == 4 || t2s.day_of_week == 5))
        {
         IsWeekend = false;
         ObjectSetString(0,"MESSAGE_LINE2",OBJPROP_TEXT,"Trading week is on.");
         ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_COLOR,Lime);
        }

      else
         if(InpRestartDay == monday && (t2s.day_of_week == 1 || t2s.day_of_week == 2 || t2s.day_of_week == 3 || t2s.day_of_week == 4 || t2s.day_of_week == 5))
           {
            IsWeekend = false;
            ObjectSetString(0,"MESSAGE_LINE2",OBJPROP_TEXT,"Trading week is on.");
            ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_COLOR,Lime);
           }

      if(NewsCnt==0 && !IsCloseTime && !IsInDrawdown && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
        {
         SetAutoTrading(true);
         Print("Autotrading enabled. ("+__FUNCTION__+")");
         Sleep(5000);
        }

     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckOvernight()
  {

//OVERNIGHT TRADING
   if(InpAllowOvernight)
      return;

   datetime day = TimeCurrent();

   string d2s = TimeToString(day,TIME_DATE);

   if(!(TimeCurrent() >= StringToTime(d2s+" "+TradeStartTime) + TimezoneOffsetSecs && TimeCurrent() <= StringToTime(d2s+" "+TradeStopTime) + TimezoneOffsetSecs))
     {
      IsCloseTime = true;

      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == true)
        {
         Print("Outside trading hours. Closing all trades and disabling autotrading...");

         if(CloseTrades())
            SetAutoTrading(false);

         DisableReason = night;
         Sleep(5000);
        }

      ObjectSetString(0,"MESSAGE_LINE3",OBJPROP_TEXT,"Outside trading hours. Overnight shutdown is active.");
      ObjectSetInteger(0,"MESSAGE_LINE3",OBJPROP_COLOR,Red);
     }

   else
      if(TimeCurrent() >= StringToTime(d2s+" "+TradeStartTime) + TimezoneOffsetSecs && TimeCurrent() <= StringToTime(d2s+" "+TradeStopTime) + TimezoneOffsetSecs)
        {
         IsCloseTime = false;

         MqlDateTime t2s;

         TimeToStruct(day,t2s);

         if(IsWeekend == false && NewsCnt==0 && !IsInDrawdown && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
           {
            SetAutoTrading(true);
            Print("Autotrading enabled. ("+__FUNCTION__+")");
            Sleep(5000);
           }

         ObjectSetString(0,"MESSAGE_LINE3",OBJPROP_TEXT,"Within trading hours. Will shutdown by "+TradeStopTime+" (UTC)");
         ObjectSetInteger(0,"MESSAGE_LINE3",OBJPROP_COLOR,Lime);
        }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckDrawdown()
  {


//DAILY DRAWDOWN



   double CurrentBalance = AccountInfoDouble(ACCOUNT_EQUITY);

   double CurrentDD     = ((CurrentBalance - StartingBalance) / StartingBalance) * 100;


   if(CurrentDD  <= -(InpMaxDailyDD))
     {
      IsInDrawdown = true;

      ObjectSetString(0,"MESSAGE_LINE4",OBJPROP_TEXT,"Daily drawdown exceeded. Equity shutdown active");
      ObjectSetInteger(0,"MESSAGE_LINE4",OBJPROP_COLOR,Red);

      if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == true)
        {
         Print("Max daily drawdown of ",(string)InpMaxDailyDD,"% hit. Closing all trades and disabling autotrading...");

         if(CloseTrades())
            SetAutoTrading(false);

         DisableReason = drawdown;

         Sleep(5000);
        }
     }

   else
      if(CurrentDD  > -(InpMaxDailyDD))
        {
         ObjectSetString(0,"MESSAGE_LINE4",OBJPROP_TEXT,"Healthy equity. Daily drawdown not exceeded.");
         ObjectSetInteger(0,"MESSAGE_LINE4",OBJPROP_COLOR,Lime);

         IsInDrawdown = false;

         datetime day = TimeCurrent();

         MqlDateTime t2s;

         TimeToStruct(day,t2s);

         if(IsWeekend == false && NewsCnt==0 && !IsCloseTime && TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false)
           {
            SetAutoTrading(true);
            Print("Autotrading enabled. ("+__FUNCTION__+")");
            Sleep(5000);
           }
        }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseTrades()
  {

   bool isClosed = false;

   int total = OrdersTotal();

   int cnt = 0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {

      if(OrderSelect(i,SELECT_BY_POS))
         isClosed = OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,clrNONE);


      if(!isClosed)
         Print("Failed to close ticket #",(string)OrderTicket(),". Error = ",GetLastError());

      else
         cnt++;

     }

   if(cnt==total)
      return true;

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseLosing()
  {

   bool isClosed = false;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {

      if(OrderSelect(i,SELECT_BY_POS))
        {

         //  Print("Order profit is ",OrderProfit());

         if(OrderProfit() <= -(InpMaxLossPerTrade))
           {
            Print("Ticket #",(string)OrderTicket()," has hit max loss allowed. Closing now...");

            isClosed = OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,clrNONE);

            if(!isClosed)
               Print("Failed to close ticket #",(string)OrderTicket(),". Error = ",GetLastError());
           }
        }



     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FloatingPL()
  {

   double pl = 0;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {

      if(OrderSelect(i,SELECT_BY_POS))
         pl += OrderProfit();

     }


   return pl;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsFound(string value, string &array[])
  {

   for(int i=0; i<ArraySize(array); i++)
     {
      if(value == array[i])
         return(true);
     }

   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsFound(double value, double &array[])
  {

   for(int i=0; i<ArraySize(array); i++)
     {
      if(value == array[i])
         return(true);
     }

   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsFound(long value, long &array[])
  {

   for(int i=0; i<ArraySize(array); i++)
     {
      if(value == array[i])
         return(true);
     }

   return(false);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddToArray(string &array[], string value)
  {

   ArrayResize(array,ArraySize(array)+1,0);
   array[ArraySize(array)-1] = value;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddToArray(int &array[], int value)
  {

   ArrayResize(array,ArraySize(array)+1,0);
   array[ArraySize(array)-1] = value;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddToArray(double &array[], double value)
  {
   ArrayResize(array,ArraySize(array)+1,0);
   array[ArraySize(array)-1] = value;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddToArray(long &array[], long value)
  {

   ArrayResize(array,ArraySize(array)+1,0);
   array[ArraySize(array)-1] = value;
  }
//+------------------------------------------------------------------+
void ResetBalance()
  {

   datetime resetTime = StringToTime(TimeToString(TimeCurrent(),TIME_DATE) + " " + InpResetTime) + TimezoneOffsetSecs;

   if(TimeCurrent() >= resetTime)
     {
      if(!FileIsExist(TimeToString(TimeCurrent(),TIME_DATE)+"_startBal.txt"))
        {
         double newBalance = MathMax(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE));

         if(StartingBalance != newBalance)
           {
            Print("Resetting starting balance for the day. New starting balance is ",(string)newBalance);
            StartingBalance = newBalance;
           }

         int handle = FileOpen(TimeToString(TimeCurrent(),TIME_DATE)+"_startBal.txt",FILE_WRITE|FILE_ANSI);

         if(handle==INVALID_HANDLE)
           {
            Print("Failed to write starting balance file. Error => ",GetLastError());
           }

         else
           {
            FileWriteString(handle,(string)newBalance);
            FileClose(handle);
           }

         if(FileIsExist(TimeToString(TimeCurrent()-86400,TIME_DATE)+"_startBal.txt"))
           {
            FileDelete(TimeToString(TimeCurrent()-86400,TIME_DATE)+"_startBal.txt");
           }
        }
      else
        {
         int handle = FileOpen(TimeToString(TimeCurrent(),TIME_DATE)+"_startBal.txt",FILE_READ|FILE_SHARE_READ);

         if(handle==INVALID_HANDLE)
           {
            Print("Failed to read starting balance file. Error => ",GetLastError());
           }

         else
           {
            string sb = FileReadString(handle);

            if(StartingBalance != (double)sb)
               StartingBalance = (double)sb;

            FileClose(handle);
           }
        }
     }



  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetAutoTrading(bool state)
  {

   int mainWindowHandle = (int)GetAncestor((int)ChartGetInteger(0,CHART_WINDOW_HANDLE), 2);
   PostMessageW(mainWindowHandle, WM_COMMAND, MT_WMCMD_EXPERTS, 0);

  }
//+------------------------------------------------------------------+
bool IsNews(string symbol)
  {

   string today = TimeToString(TimeCurrent(),TIME_DATE);

   string parts[];

   StringSplit(today,StringGetCharacter(".",0),parts);

   if(ArraySize(parts) == 0)
      return false;

   today = "";

   today += parts[1]+"-"+parts[2]+"-"+parts[0];


   bool check = false;

   string symcopy = symbol;
   int    len     = StringLen(symcopy);

   string curr1 = StringSubstr(symcopy,0,(int)len/2);
   string curr2 = StringSubstr(symcopy,(int)len/2,(int)len/2);

   if(StringFind(symbol,"US30") >= 0 || StringFind(symbol,"US100") >= 0 || StringFind(symbol,"NAS100") >= 0)
     {
      curr1 = "USD";
      curr2 = "USD";
     }

   if(StringFind(symbol,"DAX") >= 0 || StringFind(symbol,"FRA") >= 0)
     {
      curr1 = "EUR";
      curr2 = "EUR";
     }

   if(StringFind(symbol,"JAP") >= 0)
     {
      curr1 = "JPY";
      curr2 = "JPY";
     }

   if(StringFind(symbol,"AUS") >= 0)
     {
      curr1 = "AUD";
      curr2 = "AUD";
     }

//Print("Currency 1 is ",curr1);
//Print("Currency 2 is ",curr2);



   for(int i=0; i<ArraySize(NewsItems); i++)
     {
      string line = NewsItems[i];

      StringToUpper(line);
      StringToUpper(curr1);
      StringToUpper(curr2);

      string newssplit[];

      StringSplit(line,StringGetCharacter(",",0),newssplit);

      if(ArraySize(newssplit)<4)
         return false;

      string newstime = TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeTo24h(newssplit[3]);

      datetime nt2d = StringToTime(newstime);

      nt2d = nt2d+TimezoneOffsetSecs;

      bool checkhigh   = InpHighImpact==true ? (StringFind(line,"HIGH") >= 0 || StringFind(line,"High") >= 0) : false;
      bool checkmedium = InpMediumImpact==true ? (StringFind(line,"MEDIUM") >= 0 || StringFind(line,"Medium") >= 0) : false;
      bool checklow    = InpLowImpact==true ? (StringFind(line,"LOW") >= 0 || StringFind(line,"Low") >= 0) : false;

      if((StringFind(line,curr1) >= 0 || StringFind(line,curr2) >= 0 || StringFind(line,"ALL") >= 0) && StringFind(line,today) >= 0 && (checkhigh || checklow || checkmedium))
        {
         string curr = StringFind(line,curr1) >= 0 ? curr1 : curr2;

         if(checkhigh)
            newsinfo = StringConcatenate("High impact news found today for ",curr," = ",newssplit[0]," @ ",nt2d);

         if(checkmedium)
            newsinfo = StringConcatenate("Medium impact news found today for ",curr," = ",newssplit[0]," @ ",nt2d);

         if(checklow)
            newsinfo = StringConcatenate("Low impact news found today for ",curr," = ",newssplit[0]," @ ",nt2d);




         if(TimeCurrent() >= nt2d-(InpPreNewsShutdownTime*60) && TimeCurrent() <= nt2d+(InpPostNewsResumeTime*60))
           {

            check = true;

            break;
           }

        }

     }



   return check;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Download()
  {

   int timeout = 2000;

   string lastMsg = "";

//resu = WebRequest("GET",file_url,cookie,NULL,timeout,post,0,results,headers);

   string msg = httpGET(file_url);//CharArrayToString(results);


// if(resu != 200)
//    return(-1);

   /* if(FileIsExist("News.csv") && msg == GetContent("News.csv"))
       return;

    int handle = FileOpen("News.csv",FILE_WRITE | FILE_BIN);

    if(handle==INVALID_HANDLE)
      {

       int mError = GetLastError();
       PrintFormat("%s error %i opening file %s",__FUNCTION__,mError,"\\Test");
       return;

      }



   // FileWriteArray(handle,results,0,ArraySize(results));
   // FileFlush(handle);
    FileWriteString(handle,msg);
    FileClose(handle);*/

   StringSplit(msg,StringGetCharacter("\n",0),NewsItems);

// Comment(resu);

   return;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayNews()
  {

   ArrayFree(News2);

   for(int i=ObjectsTotal(0,-1,-1)-1; i>=0; i--)
     {
      string name = ObjectName(0,i);

      if(StringFind(name,"NEWS") >= 0)
         ObjectDelete(0,name);
     }

   string News[];


   for(int i=0; i<ArraySize(NewsItems); i++)
     {
      AddToArray(News,NewsItems[i]);
     }


   int ypos = 160;

   CreateObject("News_BOARD",OBJ_RECTANGLE_LABEL,10,100,330,500,4,Red,FG,Teal,"");
   ObjectSetInteger(0,"News_BOARD",OBJPROP_BORDER_TYPE,BORDER_FLAT);

   CreateObject("News_PREV",OBJ_BUTTON,237,570,42,15,4,Red,FG,Red,"PREV");
   CreateObject("News_NEXT",OBJ_BUTTON,285,570,42,15,4,Red,FG,Red,"NEXT");

   ObjectSetInteger(0,"News_PREV",OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,"News_NEXT",OBJPROP_FONTSIZE,8);

   ObjectSetString(0,"News_PREV",OBJPROP_FONT,"Candara");
   ObjectSetString(0,"News_NEXT",OBJPROP_FONT,"Candara");

   objectCreate2(OBJ_LABEL,"NEWS TITLE",40,120,100,100,"NEWS LINEUP FOR "+TimeToString(TimeCurrent(),TIME_DATE),16777215,16777215,BG,10);
   objectCreate2(OBJ_LABEL,"NEWS BREAK",40,140,100,100,"==============================",16777215,16777215,BG,10);

   bool isNewPage = false;
   int yPosCopy = 0;

   for(int i=0; i<ArraySize(News); i++)
     {
      bool checkhigh   = InpHighImpact==true ? (StringFind(News[i],"HIGH") >= 0 || StringFind(News[i],"High") >= 0) : false;
      bool checkmedium = InpMediumImpact==true ? (StringFind(News[i],"MEDIUM") >= 0 || StringFind(News[i],"Medium") >= 0) : false;
      bool checklow    = InpLowImpact==true ? (StringFind(News[i],"LOW") >= 0 || StringFind(News[i],"Low") >= 0) : false;

      string today = TimeToString(TimeCurrent(),TIME_DATE);

      string parts[];

      StringSplit(today,StringGetCharacter(".",0),parts);

      if(ArraySize(parts) == 0)
         return;

      today = "";

      today += parts[1]+"-"+parts[2]+"-"+parts[0];

      if(StringFind(News[i],today) < 0 || (!checkhigh && !checkmedium && !checklow))
         continue;

      color textColor = checkhigh ? Red : checkmedium ? Orange : BG;

      string newsItem = News[i];
      string td = ","+today;

      string parts2[];

      StringSplit(newsItem,StringGetCharacter(",",0),parts2);

      newsItem = "";

      for(int k=0; k<ArraySize(parts2); k++)
        {
         newsItem += parts2[k] + ",";

         if((StringFind(parts2[k],"am") >= 0 || StringFind(parts2[k],"pm") >= 0) && StringFind(parts2[k],":") >= 0)
            break;
        }

      string impact = (StringFind(News[i],"HIGH") >= 0 || StringFind(News[i],"High") >= 0) ? ",High":
                      (StringFind(News[i],"MEDIUM") >= 0 || StringFind(News[i],"Medium") >= 0) ? ",Medium":
                      (StringFind(News[i],"LOW") >= 0 || StringFind(News[i],"Low") >= 0) ? ",Low":
                      "";

      StringReplace(newsItem,td,"");
      StringReplace(newsItem,impact,"");
      StringReplace(newsItem,",,",",");

      string lastChar = StringSubstr(newsItem,StringLen(newsItem)-1,1);

      if(lastChar==",")
         newsItem = StringSubstr(newsItem,0,StringLen(newsItem)-1);


      int newsBoardLowerLimit = 550;



      if(isNewPage==false)
         yPosCopy = ypos;

      if(ypos >= newsBoardLowerLimit)
        {
         if(isNewPage==false)
           {
            yPosCopy = 160;
            isNewPage = true;
           }

         if(NewsPage==2)
           {
            for(int z=ObjectsTotal(0,-1,-1)-1; z>=0; z--)
              {
               string name = ObjectName(0,z,-1,-1);

               if(StringFind(name,"NEWS_") >= 0)
                  ObjectDelete(0,name);
              }
            //ypos = ypos - 390;
            objectCreate2(OBJ_LABEL,"NEWS2_"+(string)(i+1),40,yPosCopy,100,100,newsItem,16777215,16777215,textColor,8,4,"Cuyabra");
           }

        }
      else
        {
         if(NewsPage==1)
           {
            for(int z=ObjectsTotal(0,-1,-1)-1; z>=0; z--)
              {
               string name = ObjectName(0,z,-1,-1);

               if(StringFind(name,"NEWS2_") >= 0)
                  ObjectDelete(0,name);
              }

            objectCreate2(OBJ_LABEL,"NEWS_"+(string)(i+1),40,ypos,100,100,newsItem,16777215,16777215,textColor,8,4,"Cuyabra");
            ObjectSetInteger(0,"NEWS_"+(string)(i+1),OBJPROP_BACK,false);
           }
        }



      ypos += 20;
      yPosCopy += 20;

     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetContent(string filename)
  {

   string content = "";

   int handle = FileOpen(filename,FILE_READ);

   if(handle==INVALID_HANDLE)
     {

      int mError = GetLastError();
      PrintFormat("%s error %i opening file %s",__FUNCTION__,mError,"\\Test");
      return"";

     }

   while(!FileIsEnding(handle))
     {
      content += FileReadString(handle);
     }

   FileClose(handle);

   return content;
  }
//+------------------------------------------------------------------+
string TimeTo24h(string time)
  {

   string t = time;

   StringToUpper(t);

   if(StringFind(t,"AM") >= 0)
     {
      StringReplace(t,"AM","");

      if(StringFind(t,"12:00") >= 0)
         return "00:00";

      if(StringLen(t) < 5)
         t = "0"+t;

      return t;
     }

   else
      if(StringFind(t,"PM") >= 0)
        {
         string parts[];
         StringSplit(t,StringGetCharacter(":",0),parts);

         if(ArraySize(parts) ==0)
            return "";

         int hour = (int)parts[0]+12 < 24 ? (int)parts[0]+12 : (int)parts[0];


         StringReplace(parts[1],"PM","");

         if(hour < 10 && StringSubstr(t,0,1) != "0")
            return "0"+(string)hour+":"+parts[1];

         else
            return (string)hour+":"+parts[1];
        }

   return "";
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void objectCreate2(ENUM_OBJECT type, string name, int xpos, int ypos, int xsize, int ysize, string text="", color pbgcolor=White, color pbordercolor=White, color pcolor=OrangeRed, int fontsize=8, int corner=4, string font="Candara")
  {

   ObjectCreate(0, name, type, 0,0,0);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,xpos+XOffset);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,ypos+YOffset);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,xsize);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,ysize);
   ObjectSetInteger(0, name, OBJPROP_COLOR,pcolor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR,pbordercolor);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,pbgcolor);
   ObjectSetInteger(0, name, OBJPROP_CORNER,corner);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,fontsize);
   ObjectSetInteger(0, name, OBJPROP_BACK,false);

  }
//+------------------------------------------------------------------+
void CloseAll(string symbol)
  {

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
         if(OrderSymbol()==symbol)
           {

            if(OrderType() <= OP_SELL)
              {
               if(InpCloseMarket)
                  bool isClosed = OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),10,clrNONE);
              }

            else
              {
               if(InpClosePending)
                  bool isDeleted = OrderDelete(OrderTicket(),clrNONE);
              }
           }
     }

  }
//+------------------------------------------------------------------+
void CreateObject(string name,ENUM_OBJECT objectype,int xpos,int ypos,int xsize,int ysize,int corner,color pcolor,color pbgcolor,color pbordercolor, string ptext,int palign=ALIGN_CENTER,int pback=false)
  {


   ObjectCreate(0,name,objectype,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_COLOR,pcolor);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,pbgcolor);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,pbordercolor);
   ObjectSetInteger(0,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xpos+XOffset);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,ypos+YOffset);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,xsize);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,ysize);
   ObjectSetInteger(0,name,OBJPROP_ALIGN,palign);
   ObjectSetString(0,name,OBJPROP_TEXT,ptext);
   ObjectSetInteger(0,name,OBJPROP_BACK,pback);


  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayDD()
  {
   string currency = AccountInfoString(ACCOUNT_CURRENCY);

   CreateObject("DD_BOARD",OBJ_RECTANGLE_LABEL,400,100,330,170,4,Red,FG,OrangeRed,"");
   ObjectSetInteger(0,"DD_BOARD",OBJPROP_BORDER_TYPE,BORDER_FLAT);

   CreateObject("INIT_ACC_LABEL",OBJ_LABEL,430,135,350,120,4,BG,BG,White,"INITIAL ACC. SIZE ("+currency+"): ");
   ObjectSetInteger(0,"INIT_ACC_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"INIT_ACC_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("INIT_ACC_BOX",OBJ_EDIT,600,125,100,30,4,FG,BG,BG,"50000");
   ObjectSetString(0,"INIT_ACC_BOX",OBJPROP_FONT,"Cuyabra");

   CreateObject("DD_LABEL",OBJ_LABEL,430,180,350,120,4,BG,BG,White,"MAX DAILY DD (%): ");
   ObjectSetInteger(0,"DD_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"DD_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("DD_BOX",OBJ_EDIT,600,170,100,30,4,FG,BG,BG,"5");
   ObjectSetString(0,"DD_BOX",OBJPROP_FONT,"Cuyabra");

   CreateObject("DD_RESET_LABEL",OBJ_LABEL,430,220,350,120,4,BG,BG,White,"RESET TIME (UTC): ");
   ObjectSetInteger(0,"DD_RESET_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"DD_RESET_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("DD_RESET_BOX",OBJ_EDIT,600,210,100,30,4,FG,BG,BG,"00:00");
   ObjectSetString(0,"DD_RESET_BOX",OBJPROP_FONT,"Cuyabra");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayNight()
  {

   CreateObject("NIGHT_BOARD",OBJ_RECTANGLE_LABEL,400,300,330,120,4,Red,FG,Teal,"");
   ObjectSetInteger(0,"NIGHT_BOARD",OBJPROP_BORDER_TYPE,BORDER_FLAT);

   CreateObject("HOURS_LABEL",OBJ_LABEL,430,375,350,120,4,BG,BG,White,"TRADING HOURS (UTC): ");
   ObjectSetInteger(0,"HOURS_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"HOURS_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("HOURS_BOX",OBJ_EDIT,600,365,100,30,4,FG,BG,BG,"07:00-16:00");
   ObjectSetString(0,"HOURS_BOX",OBJPROP_FONT,"Cuyabra");

   CreateObject("HOURS_BUTTON_LABEL",OBJ_LABEL,430,335,350,120,4,BG,BG,White,"ALLOW NIGHT TRADING?: ");
   ObjectSetString(0,"HOURS_BUTTON_LABEL",OBJPROP_FONT,"Candara");
   ObjectSetInteger(0,"HOURS_BUTTON_LABEL",OBJPROP_FONTSIZE,10);

   CreateObject("HOURS_BUTTON",OBJ_BUTTON,600,325,100,30,4,BG,Red,BG,"NO");
   ObjectSetString(0,"HOURS_BUTTON",OBJPROP_FONT,"Cuyabra");

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayWeekend()
  {

   CreateObject("WEEKEND_BOARD",OBJ_RECTANGLE_LABEL,800,100,350,170,4,Red,FG,Blue,"");
   ObjectSetInteger(0,"WEEKEND_BOARD",OBJPROP_BORDER_TYPE,BORDER_FLAT);

   CreateObject("WEEKEND_BUTTON_LABEL",OBJ_LABEL,830,135,350,120,4,BG,BG,White,"ALLOW WEEKEND TRADING?: ");
   ObjectSetInteger(0,"WEEKEND_BUTTON_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"WEEKEND_BUTTON_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("WEEKEND_BUTTON",OBJ_BUTTON,1020,130,100,30,4,BG,Red,BG,"NO");
   ObjectSetString(0,"WEEKEND_BUTTON",OBJPROP_FONT,"Cuyabra");

   CreateObject("WEEKEND_LABEL",OBJ_LABEL,830,177,350,120,4,BG,BG,White,"FRIDAY SHUTDOWN (UTC): ");
   ObjectSetInteger(0,"WEEKEND_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"WEEKEND_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("WEEKEND_BOX",OBJ_EDIT,1020,172,100,30,4,FG,BG,BG,"18:00");
   ObjectSetString(0,"WEEKEND_BOX",OBJPROP_FONT,"Cuyabra");

   CreateObject("WEEKEND_RESTART_BUTTON_LABEL",OBJ_LABEL,830,217,350,120,4,BG,BG,White,"WEEK RESTARTS ON?: ");
   ObjectSetInteger(0,"WEEKEND_RESTART_BUTTON_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"WEEKEND_RESTART_BUTTON_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("WEEKEND_RESTART_BUTTON",OBJ_BUTTON,1020,212,100,30,4,FG,Teal,BG,"MONDAY");
   ObjectSetString(0,"WEEKEND_RESTART_BUTTON",OBJPROP_FONT,"Cuyabra");

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayNewsSettings()
  {


   CreateObject("N_BOARD",OBJ_RECTANGLE_LABEL,800,300,350,300,4,Red,FG,Yellow,"");
   ObjectSetInteger(0,"N_BOARD",OBJPROP_BORDER_TYPE,BORDER_FLAT);


   CreateObject("N_BUTTON_LABEL",OBJ_LABEL,830,335,350,120,4,BG,BG,White,"TRADE DURING NEWS?: ");
   ObjectSetInteger(0,"N_BUTTON_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"N_BUTTON_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("N_BUTTON",OBJ_BUTTON,1020,330,100,30,4,BG,Red,BG,"NO");
   ObjectSetString(0,"N_BUTTON",OBJPROP_FONT,"Cuyabra");

   CreateObject("N_HIGH_LABEL",OBJ_LABEL,830,375,350,120,4,BG,BG,White,"FILTER HIGH IMPACT?: ");
   ObjectSetInteger(0,"N_HIGH_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"N_HIGH_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("N_HIGH_BUTTON",OBJ_BUTTON,1020,370,100,30,4,BG,Green,BG,"YES");
   ObjectSetString(0,"N_HIGH_BUTTON",OBJPROP_FONT,"Cuyabra");

   CreateObject("N_MEDIUM_LABEL",OBJ_LABEL,830,415,350,120,4,BG,BG,White,"FILTER MEDIUM IMPACT?: ");
   ObjectSetInteger(0,"N_MEDIUM_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"N_MEDIUM_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("N_MEDIUM_BUTTON",OBJ_BUTTON,1020,410,100,30,4,BG,Green,BG,"YES");
   ObjectSetString(0,"N_MEDIUM_BUTTON",OBJPROP_FONT,"Cuyabra");

   CreateObject("N_LOW_LABEL",OBJ_LABEL,830,455,350,120,4,BG,BG,White,"FILTER LOW IMPACT?: ");
   ObjectSetInteger(0,"N_LOW_LABEL",OBJPROP_FONTSIZE,10);
   ObjectSetString(0,"N_LOW_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("N_LOW_BUTTON",OBJ_BUTTON,1020,450,100,30,4,BG,Green,BG,"YES");
   ObjectSetString(0,"N_LOW_BUTTON",OBJPROP_FONT,"Cuyabra");

   CreateObject("N_STOP_LABEL",OBJ_LABEL,830,497,350,120,4,BG,BG,White,"STOP TRADES PRE-NEWS(MINS):");
   ObjectSetInteger(0,"N_STOP_LABEL",OBJPROP_FONTSIZE,9);
   ObjectSetString(0,"N_STOP_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("N_STOP_BOX",OBJ_EDIT,1020,490,100,30,4,FG,BG,BG,"15");
   ObjectSetString(0,"N_STOP_BOX",OBJPROP_FONT,"Cuyabra");


   CreateObject("N_START_LABEL",OBJ_LABEL,830,537,350,120,4,BG,BG,White,"START TRADES POST-NEWS(MINS): ");
   ObjectSetInteger(0,"N_START_LABEL",OBJPROP_FONTSIZE,9);
   ObjectSetString(0,"N_START_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("N_START_BOX",OBJ_EDIT,1020,530,100,30,4,FG,BG,BG,"15");
   ObjectSetString(0,"N_START_BOX",OBJPROP_FONT,"Cuyabra");




  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayMessage()
  {

   CreateObject("MESSAGE_BOARD",OBJ_RECTANGLE_LABEL,400,460,330,140,4,Red,FG,Teal,"");
   ObjectSetInteger(0,"MESSAGE_BOARD",OBJPROP_BORDER_TYPE,BORDER_FLAT);

   CreateObject("MESSAGE_LINE1",OBJ_LABEL,420,480,350,120,4,BG,BG,White,"No scheduled news at the moment.");
   ObjectSetString(0,"MESSAGE_LINE1",OBJPROP_FONT,"Cuyabra");
   ObjectSetInteger(0,"MESSAGE_LINE1",OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,"MESSAGE_LINE1",OBJPROP_COLOR,Lime);

   CreateObject("MESSAGE_LINE2",OBJ_LABEL,420,505,350,120,4,BG,BG,White,"Trading week is on.");
   ObjectSetString(0,"MESSAGE_LINE2",OBJPROP_FONT,"Cuyabra");
   ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,"MESSAGE_LINE2",OBJPROP_COLOR,Lime);

   CreateObject("MESSAGE_LINE3",OBJ_LABEL,420,530,350,120,4,BG,BG,White,"Within trading hours. Shutdown by "+TradeStopTime+" (UTC)");
   ObjectSetString(0,"MESSAGE_LINE3",OBJPROP_FONT,"Cuyabra");
   ObjectSetInteger(0,"MESSAGE_LINE3",OBJPROP_FONTSIZE,8);

   CreateObject("MESSAGE_LINE4",OBJ_LABEL,420,555,350,120,4,BG,BG,White,"Healthy equity. Daily drawdown not exceeded.");
   ObjectSetString(0,"MESSAGE_LINE4",OBJPROP_FONT,"Cuyabra");
   ObjectSetInteger(0,"MESSAGE_LINE4",OBJPROP_FONTSIZE,8);


  }
//+------------------------------------------------------------------+
void GetInputs()
  {
   InpMaxDailyDD = (double)(ObjectGetString(0,"DD_BOX",OBJPROP_TEXT));
   InpResetTime = ObjectGetString(0,"DD_RESET_BOX",OBJPROP_TEXT);
   InpAllowOvernight = ObjectGetString(0,"HOURS_BUTTON",OBJPROP_TEXT) == "NO" ? false : true;
   InpTradingHours = ObjectGetString(0,"HOURS_BOX",OBJPROP_TEXT);
   InpWeekendTrading = ObjectGetString(0,"WEEKEND_BUTTON",OBJPROP_TEXT) == "NO" ? false : true;
   InpFridayShutdownTime = ObjectGetString(0,"WEEKEND_BOX",OBJPROP_TEXT);
   InpRestartDay = ObjectGetString(0,"WEEKEND_RESTART_BUTTON",OBJPROP_TEXT) == "SUNDAY" ? sunday : monday;
   InpTradeNews = ObjectGetString(0,"N_BUTTON",OBJPROP_TEXT) == "NO" ? false : true;
   InpHighImpact = ObjectGetString(0,"N_HIGH_BUTTON",OBJPROP_TEXT) == "NO" ? false : true;
   InpMediumImpact = ObjectGetString(0,"N_MEDIUM_BUTTON",OBJPROP_TEXT) == "NO" ? false : true;
   InpLowImpact = ObjectGetString(0,"N_LOW_BUTTON",OBJPROP_TEXT) == "NO" ? false : true;
   InpPreNewsShutdownTime = (int)(ObjectGetString(0,"N_STOP_BOX",OBJPROP_TEXT));
   InpPostNewsResumeTime = (int)(ObjectGetString(0,"N_START_BOX",OBJPROP_TEXT));
   InpInitAccSize        = (double)(ObjectGetString(0,"INIT_ACC_BOX",OBJPROP_TEXT));

   string parts[];

   StringSplit(InpTradingHours,StringGetCharacter("-",0),parts);

   if(ArraySize(parts) < 2 || !(StringSubstr(InpTradingHours,2,1)==":" && StringSubstr(InpTradingHours,5,1)=="-"  && StringSubstr(InpTradingHours,8,1)==":"))
     {
      MessageBox("Please set trading hours correctly. Format should be XX:XX-YY:YY");
      return;
     }

   FridayOff = false;

   TradeStartTime = parts[0];
   TradeStopTime  = parts[1];

   StringTrimLeft(StringTrimRight(TradeStartTime));
   StringTrimLeft(StringTrimRight(TradeStopTime));
  }
//+------------------------------------------------------------------+
void DisplayInfo()
  {

   string name = AccountInfoString(ACCOUNT_COMPANY);
   string time = TimeToString(TimeCurrent(),TIME_MINUTES);
   string utcTime = TimeToString(TimeCurrent()-TimezoneOffsetSecs,TIME_MINUTES);
   string balance = (string)AccountInfoDouble(ACCOUNT_EQUITY);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);

   double CurrentBalance = AccountInfoDouble(ACCOUNT_EQUITY);

   string stopOut     = (string)(StartingBalance-((InpMaxDailyDD/100)*InpInitAccSize));

   if(StringFind(stopOut,".") >= 0)
      stopOut = StringSubstr(stopOut,0,StringFind(stopOut,".")+3);

   CreateObject("SERVER_NAME_LABEL",OBJ_LABEL,10,620,350,120,4,BG,BG,White,"SERVER: ");
   ObjectSetString(0,"SERVER_NAME_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("SERVER_NAME",OBJ_LABEL,80,620,350,120,4,BG,BG,White,name);
   ObjectSetString(0,"SERVER_NAME",OBJPROP_FONT,"Cuyabra");

   CreateObject("SERVER_TIME_LABEL",OBJ_LABEL,400,620,350,120,4,BG,BG,White,"SERVER TIME: ");
   ObjectSetString(0,"SERVER_TIME_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("SERVER_TIME",OBJ_LABEL,490,620,350,120,4,BG,BG,White,time);
   ObjectSetString(0,"SERVER_TIME",OBJPROP_FONT,"Cuyabra");

   CreateObject("UTC_TIME_LABEL",OBJ_LABEL,800,620,350,120,4,BG,BG,White,"UTC TIME: ");
   ObjectSetString(0,"UTC_TIME_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("UTC_TIME",OBJ_LABEL,880,620,350,120,4,BG,BG,White,utcTime);
   ObjectSetString(0,"UTC_TIME",OBJPROP_FONT,"Cuyabra");

   CreateObject("STARTING_BALANCE_LABEL",OBJ_LABEL,10,70,350,120,4,BG,BG,White,"DAILY STARTING EQUITY: ");
   ObjectSetString(0,"STARTING_BALANCE_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("STARTING_BALANCE",OBJ_LABEL,160,70,350,120,4,BG,BG,White,(string)(StartingBalance)+" "+currency);
   ObjectSetString(0,"STARTING_BALANCE",OBJPROP_FONT,"Cuyabra");

   CreateObject("CURRENT_BALANCE_LABEL",OBJ_LABEL,400,70,350,120,4,BG,BG,White,"CURRENT EQUITY: ");
   ObjectSetString(0,"CURRENT_BALANCE_LABEL",OBJPROP_FONT,"Candara");

   color equityColor = (double)balance >= StartingBalance ? Lime : Red;
   CreateObject("CURRENT_BALANCE",OBJ_LABEL,510,70,350,120,4,equityColor,BG,White,balance+" "+currency);
   ObjectSetString(0,"CURRENT_BALANCE",OBJPROP_FONT,"Cuyabra");

   CreateObject("EQUITY_STOPOUT_LABEL",OBJ_LABEL,800,70,350,120,4,BG,BG,White,"EQUITY STOPOUT FOR TODAY: ");
   ObjectSetString(0,"EQUITY_STOPOUT_LABEL",OBJPROP_FONT,"Candara");

   CreateObject("EQUITY_STOPOUT",OBJ_LABEL,980,70,350,120,4,BG,BG,White,stopOut+" "+currency);
   ObjectSetString(0,"EQUITY_STOPOUT",OBJPROP_FONT,"Cuyabra");

  }
//+------------------------------------------------------------------+
string GetTZOffset()
  {
   
   double to = TimezoneOffsetSecs/3600;
   
   string tzoffset = (string)(to);

   if(StringFind(tzoffset,".") >= 0)
     {
      tzoffset = StringSubstr(tzoffset,0,StringFind(tzoffset,"."));
      tzoffset = tzoffset+":30";
     }

   return tzoffset;
  }
//+------------------------------------------------------------------+
