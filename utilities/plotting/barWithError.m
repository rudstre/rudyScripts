function barWithError(x,data,error,varargin)
bar(x,data,varargin{:})
hold on
er = errorbar(x,data,error);
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
hold off
