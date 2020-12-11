function T = enhance_morph_tophat(imgin, kernsz)
    if nargin < 2
        kernsz = 9;
    end
    T = imgin - imreconstruct(imerode(imgin,strel('disk',kernsz)), imgin);
    ss = 0.5*std(double(T(T>0)));
    ss = cast(ss,'like',T);
    T = max(0,T-ss).^0.8;
    % T = imopen(T,ones(2));
end