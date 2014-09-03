addpath('~/matlabPyrTools')
addpath('~')
in = '/om/user/ardila/Variation00_20110203/'
out = '/om/user/ardila/foveated_Variation00_20110203/'
matlabpool 12
f = dir(in)
parfor i = 1:size(f,1)
	file = f(i).name
	if file(end) == 'g'
		foveate([in, file], [out, file])
	end
end
