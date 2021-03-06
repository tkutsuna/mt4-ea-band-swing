//+------------------------------------------------------------------+
//|                                                 KeltnerSwing.mq4 |
//|                               Copyright 2016, Teruyoshi Kutsuna. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Teruyoshi Kutsuna."
#property link      ""
#property version   "1.00"
#property strict

#define MAGIC 2016061401        

//--- input parameters
input int Period = 20;
input double OpenDeviations = 2.0;
input double CloseDeviations = 1.5;

input double Lots = 1.0;
input int Slip = 10;
input double StopLossPoint = 400;
input string Comments = " ";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    int ticket = -1;
    int ordersCount = 0;
    ordersCount = countOrders(Symbol(), MAGIC);
//    Print("ordersCount: " + ordersCount);

    //買いポジションのエグジット
    if (ordersCount > 0 && (Close[1] >= getUpperBand4Close(1) || Low[1] < iLow(NULL, PERIOD_H4, 1))) {
//    if (ordersCount > 0 && Close[1] >= getUpperBand4Close(1)) {
        closeAll();
    }    
    
    //売りポジションのエグジット
    else if (ordersCount < 0 && (Close[1] <= getLowerBand4Close(1) || High[1] > iHigh(NULL, PERIOD_H4, 1))) {
//    else if (ordersCount < 0 && Close[1] <= getLowerBand4Close(1)) {
        closeAll();
    }    

    ordersCount = countOrders(Symbol(), MAGIC);
    
    //買いエントリー
    if (ordersCount == 0 && Close[2] < getLowerBand(2) && getLowerBand(1) < Close[1] && Close[1] < getLowerBandNarrow(1) 
            && Close[2] > iLow(NULL, PERIOD_H4, 2)
        ) {  
        ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slip, 0, 0, Comments, MAGIC, 0, Blue);
    }
    
    //売りエントリー
    else if (ordersCount == 0 && Close[2] > getUpperBand(2) && getUpperBandNarrow(1) < Close[1] && Close[1] < getUpperBand(1) 
            && Close[2] < iHigh(NULL, PERIOD_H4, 2)
        ) {   
        ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slip, 0, 0, Comments, MAGIC, 0, Red);     
    }
    
    if (ticket > -1) {
        if (OrderSelect(ticket, SELECT_BY_TICKET)) {
            double stoploss = OrderType() == OP_BUY ? OrderOpenPrice() - StopLossPoint * Point : OrderOpenPrice() + StopLossPoint * Point;
            OrderModify(ticket, OrderOpenPrice(), stoploss, 0, 0, Orange); // must set SL and TP here through OrderModify
        }
   }
 
}

double getBand(int period, double deviations, int line, int shift) {
//    return iCustom(NULL, 0, "Keltner Channels B", period, 0, 5, period, deviations, false, line, shift);
    return iCustom(NULL, 0, "Bands", period, 0, deviations, line, shift);
}

double getUpperBand(int shift) {
    return getBand(Period, OpenDeviations, 1, shift);
}

double getLowerBand(int shift) {
    return getBand(Period, OpenDeviations, 2, shift);
}

double getUpperBandNarrow(int shift) {
    return getBand(Period, OpenDeviations - 0.3, 1, shift);
}

double getLowerBandNarrow(int shift) {
    return getBand(Period, OpenDeviations - 0.3, 2, shift);
}

double getUpperBand4Close(int shift) {
    return getBand(Period, CloseDeviations, 1, shift);
}

double getLowerBand4Close(int shift) {
    return getBand(Period, CloseDeviations, 2, shift);
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int countOrders(string symbol, int magic) {
    int buys = 0, sells = 0;

    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderSymbol() == symbol && OrderMagicNumber() == magic) {
            if(OrderType() == OP_BUY) buys++;
            if(OrderType() == OP_SELL) sells++;
        }
    }

    //--- return orders volume
    if (buys > 0) return(buys);
    else return(-sells);
}

//+------------------------------------------------------------------+
//| close all order                                                  |
//+------------------------------------------------------------------+
void closeAll() {
    int result;
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderMagicNumber() != MAGIC || OrderSymbol() != Symbol()) continue;
        
        //--- check order type 
        if (OrderType() == OP_BUY) {
            result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, White);
        } else if (OrderType() == OP_SELL) {
            result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, White);
        }
        
        if (!result) {
            Print("OrderClose error ", GetLastError());
        }
    }
}
