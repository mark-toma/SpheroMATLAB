function myAccelCallback(src,evt,hp,window)

t = src.time_log;
t = t - t(1);
ar = appendNorm(src.accel_raw_log);
af = appendNorm(src.accel_filt_log);
ao = src.accel_one_log;

for ii = 1:4
  set(hp.har(ii),'xdata',t,'ydata',ar(ii,:));
end

for ii = 1:4
  set(hp.haf(ii),'xdata',t,'ydata',af(ii,:));
end

set(hp.hao,'xdata',t,'ydata',ao);

% adjust axes limits
if max(t) > window
  xlims(1) = max(t) - window;
  xlims(2) = max(t);
else
  xlims(1) = min(t);
  xlims(2) = xlims(1) + window;
end

set(hp.hax,'xlim',xlims);
drawnow;


end

function out = appendNorm(in)
out = [in;sqrt(sum(in.^2))];
end