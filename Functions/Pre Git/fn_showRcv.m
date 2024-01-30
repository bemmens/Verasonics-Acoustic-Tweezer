function fn_showRcv()
load RcvData
load Receive
load startSample
load endSample
imagesc(RcvData{1}(Receive(1).startSample:Receive(1).endSample,:,1))
end