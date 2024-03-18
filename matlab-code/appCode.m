% clear all;

% Import origal image
[file,path] = uigetfile('*.jpg');
I=imread(file);
fprintf('Import the image: %s \n',file)
fig1 = figure;
% subplot(1,2,1)
imshow(I);
imgsize=[256 192];

[x(1),y(1)] = ginput(1);
hold on
plot(x,y,'.r');
[x(2),y(2)] = ginput(1);
hold on
plot(x,y,'.r');

% Crop the ROI
rectangle('Position',[x(1)  y(1) x(2)-x(1) y(2)-y(1)],'EdgeColor','r');
Iin = imresize(imcrop(I,[x(1) y(1) x(2)-x(1) y(2)-y(1)]),imgsize);
fig2 = figure;
% subplot(1,2,2)
imshow(Iin); 
hold on


% Detect key points using PoseEstimator
detector = posenet.PoseEstimator;
keypoints = detectPose(detector,Iin);

% Display the key points and links on the image
new_keypoints=[mean(keypoints(2:3,1)) mean(keypoints(2:3,2)) mean(keypoints(2:3,3))   % 1 center of eyes
    mean(keypoints(6:7,1)) mean(keypoints(6:7,2)) mean(keypoints(6:7,3))              % 2 center of shoulders
    keypoints(6,1:3)                                                                  % 3 left shoulder
    keypoints(7,1:3)                                                                  % 4 right shoulder
    keypoints(8,1:3)                                                                  % 5 left elbow
    keypoints(10,1:3)                                                                 % 6 left wrist
    keypoints(9,1:3)                                                                  % 7 right elbow
    keypoints(11,1:3)                                                                 % 8 right wrist
    mean(keypoints(12:13,1)) mean(keypoints(12:13,2)) mean(keypoints(12:13,3))        % 9 center of hips
    keypoints(12,1:3)                                                                 % 10 left hip
    keypoints(13,1:3)                                                                 % 11 right hip
    keypoints(14,1:3)                                                                 % 12 left knee
    keypoints(16,1:3)                                                                 % 13 left ankle
    keypoints(15,1:3)                                                                 % 14 right knee
    keypoints(17,1:3)];                                                               % 15 right ankle

for i=2:size(new_keypoints,1)
    plot(new_keypoints(i,1),new_keypoints(i,2),'.r','markersize',20)
end
% To connect joints: start joint and end joint. Index from new_keypoints
% 1 0 eye center
% 2 1 center of shoulders
% 3 2 left shoulder
% 4 3 right shoulder
% 5 4 left elbow
% 6 5 left wrist
% 7 6 right elbow
% 8 7 right wrist
% 9 8 center of hip  
%10 9 left hip
%11 10 right hip
line_connect=[1 2   % eye to center of shoulders
    3 4             % left to right shoulders 
    3 5             % left shoulder to elbow
    5 6             % left elbow to left wrist
    4 7             % right shoulder to elbow
    7 8             % elbow to wrist
    2 9             % center of shoulder to center of hip  
    10 11           % left to right hips
    10 12           % left hip to knee
    12 13           % knee to ankle
    11 14           % right hip to knee
    14 15];         % knee to ankle
for i=2:size(line_connect,1)
    plot([new_keypoints(line_connect(i,1),1) new_keypoints(line_connect(i,2),1)],[new_keypoints(line_connect(i,1),2) new_keypoints(line_connect(i,2),2)],'-r', 'LineWidth', 3)
end

print(fig1,'originImg','-dpng')
print(fig2,'cropImg','-dpng')
close(fig1)
close(fig2)


% Individual posture degree
for i=1 : size(line_connect,1)
    degree_post(i,1) = atand(abs((new_keypoints(line_connect(i,2),2)-new_keypoints(line_connect(i,1),2))/(new_keypoints(line_connect(i,2),1)-new_keypoints(line_connect(i,1),1))));    
end

% Back posture score
if degree_post(7,1) < 70 && degree_post(2,1) > 20 %(degree_post(7,1) < 70 && degree_post(2,1) > 0)
    back_post = 'B4';
    app_back_post = '[4]Leaning forward & Flexous';
    disp('(4) Back posture: Leaning forward & Flexous')
elseif degree_post(7,1) >= 70 && degree_post(2,1) > 20 % && (degree_post(7,1) < 70 && degree_post(2,1) > 0)
    back_post = 'B3';
    app_back_post = '[3]Flexous';
    disp('(3) Back posture: Flexous')
elseif degree_post(7,1) < 70
    back_post = 'B2';
    app_back_post = '[2]Leaning forward';
    disp('(2) Back posture: Leaning forward')
else %degree_post(7,1) >= 70
    back_post = 'B1';
    app_back_post = '[1]Upright';
    disp('(1) Back posture: Upright')
end

% Arm posture score
if (keypoints(10,2) <= keypoints(8,2)) && (keypoints(11,2) <= keypoints(9,2))
    arm_post = 'A3';
    app_arm_post = '[3]Both above elbow joint';
    disp('(3) Arm posture: Both above elbow joint')
elseif (keypoints(10,2) <= keypoints(8,2)) || (keypoints(11,2) <= keypoints(9,2))
    arm_post = 'A2';
    app_arm_post = '[2]One above elbow joint';
    disp('(2) Arm posture: One above elbow joint')
else %(keypoints(10,2) > keypoints(8,2)) && (keypoints(11,2) > keypoints(9,2))
    arm_post = 'A1';
    app_arm_post = '[1]Both below elbow joint';
    disp('(1) Arm posture: Both below elbow joint')
end

% Legs posture score    
Q3 = 80;
Q1 = 20;
walking_pop = menu('Is the worker walking?','YES','NO');
if walking_pop == 1
    leg_post = 'L7';
    app_leg_post = '[7]Walking';
    disp('(7) Leg posture: Walking')
else
    leg_visual_pop = menu('Are legs visible in the image?','YES','NO');
    if leg_visual_pop == 2
        leg_invisible_pop = menu('Please select the legs posture:','Sitting position','Standing with legs upright','Standing with one leg upright','Standing with legs bent','Standing with one leg bent','Kneeling on one or both knees');
        if leg_visual_pop == 2
            leg_post = 'L2';
            app_leg_post = '[2]Standing with legs upright';
            disp('(2) Leg posture: Standing with legs upright')
        elseif leg_visual_pop == 3
            leg_post = 'L3';
            app_leg_post = '[3]Standing with one leg upright';
            disp('(3) Leg posture: Standing with one leg upright')
        elseif leg_visual_pop == 4
            leg_post = 'L4';
            app_leg_post = '[4]Standing with legs bent';
            disp('(4) Leg posture: Standing with legs bent')
        elseif leg_visual_pop == 5
            leg_post = 'L5';
            app_leg_post = '[5]Standing with one leg bent';
            disp('(5) Leg posture: Standing with one leg bent')
        elseif leg_visual_pop == 6
            leg_post = 'L6';
            app_leg_post = '[6]Kneeling on one or both knees';
            disp('(6) Leg posture: Kneeling on one or both knees')
        elseif leg_visual_pop == 1
            leg_post = 'L1';
            app_leg_post = '[1]Sitting position';
            disp('(1) Leg posture: Sitting position')    
        end
    else
        if degree_post(10,1) < Q1 || degree_post(12,1) < Q1
            leg_post = 'L6';
            app_leg_post = '[6]Kneeling on one or both knees';
            disp('(6) Leg posture: Kneeling on one or both kneesn')
        elseif (degree_post(9,1) < Q1 || degree_post(11,1) < Q1) || ((keypoints(14,2) < keypoints(12,2)) || (keypoints(15,2) < keypoints(13,2)))
            leg_post = 'L1';
            app_leg_post = '[1]Sitting position';
            disp('(1) Leg posture: Sitting position')
        elseif degree_post(10,1) >= Q3 && degree_post(12,1) >= Q3 %(degree_post(9,1) > Q3 && degree_post(11,1) > Q3) && (degree_post(10,1) > Q3 && degree_post(12,1) > Q3)
            leg_post = 'L2';
            app_leg_post = '[2]Standing with legs upright';
            disp('(2) Leg posture: Standing with legs upright')        
        elseif (degree_post(10,1) < Q3 && degree_post(10,1) > Q1) && (degree_post(12,1) < Q3 && degree_post(12,1) > Q1) %(degree_post(9,1) < Q3 && degree_post(11,1) < Q3) && (degree_post(10,1) < Q3 && degree_post(12,1) < Q3)
            leg_post = 'L4';
            app_leg_post = '[4]Standing with legs bent';
            disp('(4) Leg posture: Standing with legs bent')
        elseif (degree_post(10,1) < Q3 && degree_post(10,1) > Q1) || (degree_post(12,1) < Q3 && degree_post(12,1) > Q1)
            leg_post = 'L5';
            app_leg_post = '[5]Standing with one leg bent';
            disp('(5) Leg posture: Standing with one leg bent')       
            disp('(3) Leg posture: Standing with one leg upright')
        else %degree_post(10,1) >= Q3 || degree_post(12,1) >= Q3 %(degree_post(9,1) >= Q3 && degree_post(10,1) >= Q3) || (degree_post(11,1) >= Q3 && degree_post(12,1) >= Q3)
            leg_post = 'L3';
            app_leg_post = '[3]Standing with one leg upright';
        end
    end
end

% Force score
force_pop = menu('How much is the product weight?','Below 10kg','10 - 20kg','Above 20kg');

if force_pop == 1
    force_weight = 'F1';
    app_force_weight = '[1]Below 10kg';
    disp('(1) Force: Below 10kg')
elseif force_pop == 2
    force_weight = 'F2';
    app_force_weight = '[2]10 - 20kg';
    disp('(2) Force: 10 - 20kg')
else
    force_weight = 'F3';
    app_force_weight = '[3]Above 20kg';
    disp('(3) Force: Above 20kg')
end

% Import OWAS score table
owasScore = readtable('owasScore.xlsx');
owasScore.Properties.VariableNames = {'L1F1','L1F2','L1F3','L2F1','L2F2','L2F3','L3F1','L3F2','L3F3','L4F1','L4F2','L4F3','L5F1','L5F2','L5F3','L6F1','L6F2','L6F3','L7F1','L7F2','L7F3'};
owasScore.Properties.RowNames = {'B1A1','B1A2','B1A3','B2A1','B2A2','B2A3','B3A1','B3A2','B3A3','B4A1','B4A2','B4A3'};

% Append row/column
LF_score = append(leg_post,force_weight);
BA_score = append(back_post,arm_post);
final_score = owasScore{BA_score,LF_score};
fprintf('ACTION LEVEL: %d \n',final_score);

app_alevel = num2str(final_score);
