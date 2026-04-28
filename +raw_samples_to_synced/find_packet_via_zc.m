function pkt_start = find_packet_via_zc(iq, tpl4, tpl6, P)
    pkt_start = NaN;
    if numel(iq) < raw_samples_to_synced.packet_total_samples(P), return; end
 
    mag4 = abs(raw_samples_to_synced.fft_xcorr(iq, tpl4));
    mag6 = abs(raw_samples_to_synced.fft_xcorr(iq, tpl6));
    med4 = median(mag4); med6 = median(mag6);
    if med4 == 0, return; end
 
    expected = 2 * (P.cp_normal + P.n_fft);
    [~, order] = sort(mag4, 'descend');
    [best_k, c6_paired] = deal(-1, 0);
    best_score = 0;
    for k = order(1:min(50,end)).'
        lo = max(1, k + expected - 50);
        hi = min(numel(mag6), k + expected + 50);
        if hi <= lo, continue; end
        m6 = max(mag6(lo:hi));
        if mag4(k) * m6 > best_score
            best_score = mag4(k) * m6;
            [best_k, c6_paired] = deal(k, m6);
        end
    end
    if best_k < 0, return; end
 
    cand = best_k - P.n_fft + 1 - P.cp_normal - raw_samples_to_synced.symbol_offset(4, P);
 
    if 20 * log10(mag4(best_k) / med4) < 25, return; end
    if c6_paired / med6 < 8, return; end
    if c6_paired / mag4(best_k) < 0.4, return; end
    if cand < 1 || cand + raw_samples_to_synced.packet_total_samples(P) - 1 > numel(iq), return; end
    if raw_samples_to_synced.mean_cp_autocorr(iq, cand, P) < 0.55, return; end
 
    pkt_start = cand;
end