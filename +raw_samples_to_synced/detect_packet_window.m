function [s, e] = detect_packet_window(iq, fs, smooth_s, thresh_factor, margin_s)
    p   = abs(iq).^2;
    win = max(1, round(smooth_s*fs));
    sm  = movmean(p, win);
    th  = thresh_factor * median(sm);
    above = sm > th;
    if ~any(above)
        error('drone_id_demod:noPacket', 'No packet found above threshold.');
    end

    d  = diff([0; above(:); 0]);
    starts = find(d == 1);
    ends   = find(d == -1) - 1;
    [~,bi] = max(ends - starts);
    s = starts(bi); e = ends(bi);
    pad = round(margin_s*fs);
    s = max(1, s - pad);
    e = min(numel(iq), e + pad);
end