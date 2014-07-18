---
layout: post
title: 【DP】Best Time to Buy and Sell Stock 
description: Given a log of stock prices compute the maximum possible earning.
category: algorithm
tags: leetcode
---
###Best Time to Buy and Sell Stock
>Say you have an array for which the ith element is the price of a given stock on day i.

>If **you were only permitted to complete at most one transaction** (ie, buy one and sell one share of the stock), design an algorithm to find the maximum profit.

####思路
[Best Time to Buy and Sell Stock](https://oj.leetcode.com/problems/best-time-to-buy-and-sell-stock/)这题似乎就是codility中的[MaxProfit](https://codility.com/programmers/lessons/7),codility把这题归到Maximum slice problem一章，不过这题有更直观的解法

####代码

```cpp
int solution(const vector<int> &A) {
    if(A.size() < 2) return 0;
    int mina = A[0];//i之前的最小值
    int maxP = 0;//整体最大收益
    for(int i : A){
        int P = i - mina;//卖出i的收益
        if(P > maxP) maxP = P;
        if(i < mina) mina = i;//更新最小值
    }
    return maxP;
}
```
###Best Time to Buy and Sell Stock II 
>Say you have an array for which the ith element is the price of a given stock on day i.

>Design an algorithm to find the maximum profit. **You may complete as many transactions as you like** (ie, buy one and sell one share of the stock multiple times). However, you may not engage in multiple transactions at the same time (ie, you must sell the stock before you buy again).

####思路
II这道题反而比较像一个Maximum slice problem，有一个重要的观察是prices[i] - prices[i-2] = (prices[i] - prices[i-1]) + (prices[i-1] - prices[i-2])，因此我们可以抽象成相邻元素差序列的最大字段和问题。
####代码

```cpp
int maxProfit(vector<int> &prices) {
    int n = prices.size();
    if(n <= 1) return 0;    
    int profit = 0;
    for(int i = 1; i < n; i++){
        int gap = prices[i] - prices[i-1];
        if(gap > 0) profit += gap;
    }
    return profit;
}
```

###Best Time to Buy and Sell Stock III 
>Say you have an array for which the ith element is the price of a given stock on day i.

>Design an algorithm to find the maximum profit. **You may complete at most two transactions**.

>Note:
>You may not engage in multiple transactions at the same time (ie, you must sell the stock before you buy again).

####思路
这题很经典，跟MaxDoubleSliceSum的第二种思路有相似之处，枚举中间点，正反扫一遍
####代码
```cpp
int maxProfit(vector<int> &prices) {
    int n = prices.size();
    if(n <= 1) return 0;
        
    //求[0,i]这个子序列的交易最大值
    int min = prices[0];
    vector<int> maxprofitA(n,0);
    for(int i = 1; i < n; i++) {
        int price = prices[i];
        int diff = price - min;
        if(maxprofitA[i-1] < diff) maxprofitA[i] = diff;
        else maxprofitA[i] = maxprofitA[i-1];
        if(price < min) min = price;
    }
    
    //求[i,n-1]这个子序列的交易最大值
    int max = prices[n-1];
    vector<int> maxprofitB(n,0);
    for(int i = n-2; i >= 0; i--) {
        int price = prices[i];
        int diff = max - prices[i];
        if(maxprofitB[i+1] < diff) maxprofitB[i] = diff;
        else maxprofitB[i] = maxprofitB[i+1];
        if(price > max) max = price;
    }
    
    //把两次交易的分割点遍历一遍
    int maxprofit = maxprofitA[n-1];//对应着在[0,n-1]进行一次交易
    for(int i = 0; i < n-1; i++) {
        maxprofitA[i] += maxprofitB[i+1]; //注意下标的含义
        if(maxprofit < maxprofitA[i]) maxprofit = maxprofitA[i];
    }
    return maxprofit;
}
```
