import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.GridLayout;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Random;

import javax.swing.BorderFactory;
import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.Timer;

public class RTS5 extends JFrame {

	//사용될 변수
    static int N;
    static String[][] kingdom;
    static Map<String, int[]> kingdoms;
    static String[] names = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
        "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
        "U", "V", "W", "X", "Y", "Z"
    };
    static int[][] soldier;
    static String[] titles = {"국왕", "영주"};
    static int[][] title;
    static String Name = "플레이어";
    static int[] player;
    
    static int turn;
    static int[][] fertile;
    
    //그래픽 변수
    static JLabel gameTitleLabel;  // 게임 제목을 표시할 라벨
    static JLabel authorLabel;  // 게임 제목을 표시할 라벨
    static JPanel mapPanel;
    static JPanel graphPanel; //그래프 판넬
    static JTextArea logArea;  // 게임 로그를 출력할 텍스트 영역
    static JButton attackButton, recruitButton;
    static boolean playerTurn = false;  // 플레이어 턴 여부
    static boolean waitingForAttack = false;  // 공격 대기 상태
    static Timer gameTimer;  // 게임 턴을 관리할 타이머
    static int currentTurnIndex;  // 군주의 현재 턴 인덱스
    static Map<String, Color> lordColors;  // 군주마다 색상 저장
    
    public RTS5() {
        setTitle("삼국지 : 천하통일");
        setSize(500, 250);  // 창 크기를 키워서 로그 출력 영역 추가
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLayout(new BorderLayout());
        
        // 메인 패널 생성
        JPanel mainPanel = new JPanel();
        mainPanel.setLayout(new BoxLayout(mainPanel, BoxLayout.Y_AXIS));
        
        // 게임 제목 라벨
        gameTitleLabel = new JLabel("삼국지 : 천하통일", JLabel.CENTER);
        gameTitleLabel.setFont(new Font("Serif", Font.BOLD, 30));  // 제목의 글씨 크기와 스타일 설정
        gameTitleLabel.setForeground(Color.RED);  // 제목 색상 설정
        gameTitleLabel.setAlignmentX(CENTER_ALIGNMENT);  // 라벨을 중앙 정렬
        
        authorLabel = new JLabel("제작자 허성준", JLabel.CENTER);
        authorLabel.setFont(new Font("Serif", Font.BOLD, 15));  // 제목의 글씨 크기와 스타일 설정
        authorLabel .setForeground(Color.BLACK);  // 제목 색상 설정
        authorLabel.setAlignmentX(CENTER_ALIGNMENT);  //
        // 라벨에 상단 공백 추가 (패딩)
        gameTitleLabel.setBorder(BorderFactory.createEmptyBorder(50, 0, 0, 0));  // 상단 20px 여백 추가
        authorLabel.setBorder(BorderFactory.createEmptyBorder(10, 0, 20, 0));  // 상단 20px 여백 추가
        
        // 맵 크기 입력 패널
        JPanel mapSizePanel = new JPanel();
        JLabel mapSizeLabel = new JLabel("맵 크기(N*N)를 입력하세요(최소 1이상): ");
        JTextField mapSizeInput = new JTextField(5);
        mapSizeLabel.setFont(new Font("SansSerif", Font.PLAIN, 16));  // 맵 크기 입력 필드 글씨 크기 변경
        mapSizeInput.setFont(new Font("SansSerif", Font.PLAIN, 16));
        JButton mapSizeButton = new JButton("확인");
        mapSizePanel.add(mapSizeLabel);
        mapSizePanel.add(mapSizeInput);
        mapSizePanel.add(mapSizeButton);

        // 행동 선택 버튼 패널
        JPanel actionPanel = new JPanel();
        attackButton = new JButton("공격하기");
        attackButton.setVisible(false);  // 초기에는 비활성화
        attackButton.setFont(new Font("SansSerif", Font.BOLD, 14));  // 버튼 글씨 크기 변경
        actionPanel.add(attackButton);  // 버튼을 패널에 추가        
        recruitButton = new JButton("징병하기");
        recruitButton.setVisible(false);  // 초기에는 비활성화
        recruitButton.setFont(new Font("SansSerif", Font.BOLD, 14));  // 버튼 글씨 크기 변경
        actionPanel.add(recruitButton);  // 버튼을 패널에 추가

        // 맵 패널
        mapPanel = new JPanel();

        // 로그 출력 패널
        logArea = new JTextArea(10, 35);  // 10줄, 50칸 크기의 로그 영역
        logArea.setEditable(false);  // 로그는 수정 불가능하게 설정
        logArea.setFont(new Font("SansSerif", Font.PLAIN, 14));  // 글씨 크기를 16으로 설정
        JScrollPane scrollPane = new JScrollPane(logArea);  // 스크롤 가능하게 추가
        scrollPane.setVisible(false);
        
        // 그래프 패널
        graphPanel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                drawGraph(g);  // 그래프 그리기 메서드 호출
            }
        };
        graphPanel.setPreferredSize(new Dimension(300, 700));  // 패널 크기 설정
        graphPanel.setVisible(false);
        
        // 메인 패널에 모든 패널 추가
        mainPanel.add(gameTitleLabel);  // 게임 제목 라벨 추가
        mainPanel.add(authorLabel);  // 제작자 이름 추가
        mainPanel.add(mapSizePanel);      
        mainPanel.add(actionPanel);
        add(mainPanel, BorderLayout.NORTH);
        add(mapPanel, BorderLayout.CENTER);
        add(scrollPane, BorderLayout.WEST);  // 하단에 로그 출력 추가
        add(graphPanel, BorderLayout.EAST);  // 그래프를 오른쪽에 배치

        // 맵 크기 설정
        mapSizeButton.addActionListener(e -> {
            try {
            	gameTitleLabel.setVisible(false);  // 게임이 시작되면 제목을 숨김
            	authorLabel.setVisible(false);  // 게임이 시작되면 제목을 숨김
                N = Integer.parseInt(mapSizeInput.getText());
                if (N < 1) throw new Exception();
                setExtendedState(JFrame.MAXIMIZED_BOTH); // 창을 최대화 상태로 설정
                initGame();  // 게임 초기화
                drawMap();  // 맵 그리기
                scrollPane.setVisible(true);
                graphPanel.setVisible(true);
                attackButton.setVisible(true);
                recruitButton.setVisible(true);
                startGameLoop();  // 게임 루프 시작
            } catch (Exception ex) {
            	System.err.println("Init Error");
            }
        });

        // 징병 버튼 클릭 시
        recruitButton.addActionListener(e -> {
            if (playerTurn) {
                recruit(player[0], player[1]);  // 플레이어 영토에서 징병
                drawMap();  // 맵 업데이트
                endPlayerTurn();  // 플레이어 턴 종료
            }
        });

        // 공격 버튼 클릭 시
        attackButton.addActionListener(e -> {
            if (playerTurn) {
            	JOptionPane.showMessageDialog(null, "인접한 영토를 클릭하세요", "공격하기", JOptionPane.INFORMATION_MESSAGE);
            }
        });

        setVisible(true);
    }
    
    // 그래프 그리기 메서드
    public void drawGraph(Graphics g) {
        // 그래프에 표시할 각 군주의 병력 계산
        Map<String, Integer> soldierCountByKingdom = new HashMap<>();
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                String lord = kingdom[i][j];
                if (lord != null) {
                    soldierCountByKingdom.put(lord, soldierCountByKingdom.getOrDefault(lord, 0) + soldier[i][j]);
                }
            }
        }

        // 병력 수를 기준으로 군주 정렬
        Entry<String, Integer>[] sortedKingdoms = soldierCountByKingdom.entrySet().toArray(new Entry[0]);
        Arrays.sort(sortedKingdoms, (a, b) -> b.getValue().compareTo(a.getValue()));

        // 상위 5개 군주만 선택 (최대 5개)
        int limit = Math.min(5, sortedKingdoms.length);
        Entry<String, Integer>[] top5Kingdoms = Arrays.copyOfRange(sortedKingdoms, 0, limit);

        // 막대 그래프 그리기
        int x = 20;  // 막대 시작 x좌표
        int barWidth = 30;  // 막대 너비
        int maxBarHeight = 220;  // 막대 최대 높이
        int maxSoldier = top5Kingdoms.length > 0 ? top5Kingdoms[0].getValue() : 1;  // 최대 병력 수

        // 설명서 추가
        g.setFont(new Font("SansSerif", Font.BOLD, 16));
        g.drawString("<설명서>", 20, 15);  // 설명서 제목 추가
        // 설명서 텍스트 추가
        g.setFont(new Font("SansSerif", Font.PLAIN, 14));
        g.drawString("1. [공격하기] : 인접한 1칸을 공격(패배시 전멸)", 5, 40);
        g.drawString("= 정복: 점령시 "+titles[0]+" 병사 "+(100/N)+"%를 주둔", 5, 60);
        g.drawString("2. [징병하기] : 인접한 칸 수만큼 징병", 5, 80);
        g.drawString("= 세금: 신하는 병사 "+(100/N)+"%를 "+titles[0]+"에게 납세", 5, 100);
        g.drawString("+)반란: "+titles[0]+"보다 군사가 많으면 반란", 5, 125);
        g.drawString("+)모든 영토 점령시 승리", 5, 145);
        
        // 상단에 <열강 5개국> 텍스트 굵게 표시
        g.setFont(new Font("SansSerif", Font.BOLD, 16));
        g.drawString("<열강 " + top5Kingdoms.length+ "국>", 20, 175);  // 상단 중앙에 표시
        g.setFont(new Font("SansSerif", Font.BOLD, 12));

        for (int i = 0; i < top5Kingdoms.length; i++) {
            String lord = top5Kingdoms[i].getKey();
            int soldiers = top5Kingdoms[i].getValue();

            // 막대 높이 계산
            int barHeight = (int) ((double) soldiers / maxSoldier * maxBarHeight);

            // 군주의 색상 가져오기
            Color lordColor = lordColors.getOrDefault(lord, Color.GRAY);
            g.setColor(lordColor);

            // 막대 그리기
            g.fillRect(x, maxBarHeight - barHeight + 50+140, barWidth, barHeight);

            // 군주 이름과 병력 수 표시
            g.setColor(Color.BLACK);
            g.drawString(lord, x - 5, maxBarHeight + 70+140);
            g.drawString("(" + soldiers + ")", x, maxBarHeight + 85+140);

            x += barWidth + 25;  // 다음 막대 위치
        }

        // <군소국> 텍스트 표시
        int remainingKingdoms = sortedKingdoms.length - limit;  // 군소국의 개수 계산
        g.setFont(new Font("SansSerif", Font.BOLD, 16));
        g.drawString("<군소 " + remainingKingdoms + "국>", 20, maxBarHeight + 120+135);  // 막대 그래프 하단에 표시
        g.setFont(new Font("SansSerif", Font.PLAIN, 12));

        // 상위 5개국을 제외한 나머지 국가를 순위별로 점으로 나열
        int y = maxBarHeight + 150 +130;  // 군소국 표시 시작 y좌표
        for (int i = limit; i < sortedKingdoms.length; i++) {
            String lord = sortedKingdoms[i].getKey();
            int soldiers = sortedKingdoms[i].getValue();

            // 군주의 색상 가져오기
            Color lordColor = lordColors.getOrDefault(lord, Color.GRAY);
            g.setColor(lordColor);

            // 작은 원(점) 그리기
            g.fillOval(20, y - 10, 10, 10);  // 점 그리기
            g.setColor(Color.BLACK);
            g.drawString(lord + " (" + soldiers + ")", 40, y);  // 점 옆에 군주 이름과 병력 수 표시

            y += 30;
        }
    }


    // 게임 초기화 메서드
    public static void initGame() {
        kingdom = new String[N][N];
        kingdoms = new HashMap<>();
        soldier = new int[N][N];  // 병력 0으로 초기화
        title = new int[N][N];
        lordColors = new HashMap<>();  // 군주마다 고유 색상 저장
        
        //턴 초기화
        turn = 0;
        currentTurnIndex = 0;
        logArea.setText("");
        
        //비옥함(징병량) 설정
        fertile = new int[N][N];
        for (int i = 0; i < N; i++) {
			for (int j = 0; j < N; j++) {
				fertile[i][j] = 8;
				if(i==0 || j==0 || i==N-1 || j==N-1)
					fertile[i][j] -= 3;
				if((i==0 && j==0) || (i==0 && j==N-1) || (i==N-1 && j==0) ||(i==N-1 && j==N-1))
					fertile[i][j] -= 2;
			}
		}
        
        // 게임 모드 선택
        int mode = JOptionPane.showOptionDialog(
            null, 
            "게임 참여 방식 선택", 
            "게임 모드 선택", 
            JOptionPane.YES_NO_OPTION, 
            JOptionPane.QUESTION_MESSAGE, 
            null, 
            new String[]{"게임 참여", "관전 모드"}, 
            "게임 참여"
        );
        
        // 플레이어 초기 설정
        player = new int[2];
        if(mode==1) {
            player[0] = N;
            player[1] = N;
        }else {
        	//Name = JOptionPane.showInputDialog(titles[0]+"을 입력하세요 (한글 3글자 권장): ");
        	player[0] = (int) (Math.random() * N);
            player[1] = (int) (Math.random() * N);
        }
        
        // 군주 생성
        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                NewLord(i, j);
            }
        }
        
        log("-게임 시작-");
    }

    // 게임 루프 시작
    public static void startGameLoop() {
        gameTimer = new Timer(0, e -> processTurn());
        gameTimer.start();
    }

    // 각 턴을 처리하는 메서드
    public static void processTurn() {    
    	
        if(currentTurnIndex%(N*N)==0) {
        	 if (kingdoms.size() <= 1) {
        		 //2차 검증
        		 String standard = null;
        		 boolean check = true;
        		 check:
        		 for (int i = 0; i < N; i++) {
					for (int j = 0; j < N; j++) {
						if(i==0 && j==0) {
							standard = kingdom[i][j];
						}
						if(standard!=kingdom[i][j])
						{
							check=false;
							break check;
						}
					}
				}
        		if(check) {
					gameTimer.stop();
					log("-게임 종료-");
					log(kingdoms.entrySet().iterator().next().getKey()+" 승리!");
					return;
        		}
             }
        	 log("-------<"+(++turn)+"턴>-------");
        }
        
        // 현재 턴의 군주 위치를 가져옴
        int x = (int) (currentTurnIndex/N);
        int y = currentTurnIndex % N;

        if (x == player[0] && y == player[1]) {
            // 플레이어 턴
        	playerTurn = true;
        	waitingForAttack = true; //공격 가능하게 설정
        	int i = player[0];
        	int j = player[1];
        	if(title[i][j]==1 && (!kingdoms.containsKey(kingdom[i][j]) || soldier[i][j] > soldier[kingdoms.get(kingdom[i][j])[0]][kingdoms.get(kingdom[i][j])[1]])) {
				//소속 군주가 패하거나 약하다면 독립에 한턴 소모
        		JOptionPane.showMessageDialog(null, "독립을 쟁취하였습니다!", "알림", JOptionPane.INFORMATION_MESSAGE);
				NewLord(i, j);
			}else {
				gameTimer.stop();  // 플레이어 턴 동안 타이머 중지
			}        
        } else {
            // AI 군주 턴
            takeAITurn(x, y);
        }

        drawMap();  // 턴이 끝날 때마다 맵 업데이트
        graphPanel.repaint();  // 턴이 끝날 때마다 그래프 업데이트

        // 다음 턴으로 넘어감
        currentTurnIndex = (currentTurnIndex + 1) % (N*N);
    }

    // AI 군주가 턴을 진행하는 메서드
    public static void takeAITurn(int i, int j) {
    	//AI 턴
		if(title[i][j]==1 && (!kingdoms.containsKey(kingdom[i][j]) || soldier[i][j] > soldier[kingdoms.get(kingdom[i][j])[0]][kingdoms.get(kingdom[i][j])[1]])) {
			//소속 군주가 패하거나
			NewLord(i, j);
		}else {
			int[][] range = {{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}};
			int randomNum = (int)(Math.random() * range.length);
			int x = i+range[randomNum][0];
			int y = j+range[randomNum][1];
			if(x>=0 && x<N && y>=0 && y<N && kingdom[i][j]!=kingdom[x][y] && soldier[i][j]>0) {
				Attack(i, j, x, y);
			}
			else{
				recruit(i, j);
			}
		}
    }

    // 밝기 기반으로 글씨 색상 결정
    public static Color getContrastingTextColor(Color bgColor) {
        // RGB 값에서 밝기 계산 (0 ~ 255 범위로 변환)
        double brightness = (0.299 * bgColor.getRed() + 0.587 * bgColor.getGreen() + 0.114 * bgColor.getBlue()) / 255;
        
        // 밝기가 0.5보다 크면 어두운 글씨(검은색), 작으면 밝은 글씨(흰색) 반환
        return (brightness > 0.5) ? Color.BLACK : Color.WHITE;
    }
    // 맵을 그리는 메서드
    public static void drawMap() {
        mapPanel.removeAll();
        mapPanel.setLayout(new GridLayout(N, N));  // N*N 그리드

        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
            	JButton territoryButton;
            	if(title[i][j]==0) {
            		//군주일 때
            		territoryButton = new JButton("<html><div style='text-align: center;'>" 
            			    + "["+titles[0]+"]<br>" 
            			    + kingdom[i][j] + "<br>" 
            			    + soldier[i][j] 
            			    + "</div></html>");
            	}else {
            		//신하일 때
            		if(i==player[0] && j==player[1]) {
            			territoryButton = new JButton("<html><div style='text-align: center;'>" 
                			    + titles[1]+"<br>" 
                			    + kingdom[i][j]+"("+Name+")" + "<br>" 
                			    + soldier[i][j] 
                			    + "</div></html>");
            		}else {
            			territoryButton = new JButton("<html><div style='text-align: center;'>" 
                			    + titles[1]+"<br>" 
                			    + kingdom[i][j] + "<br>" 
                			    + soldier[i][j] 
                			    + "</div></html>");
            		}
            	}
            	territoryButton.setFont(new Font("SansSerif", Font.BOLD, 14));
            	    	
                int finalI = i;
                int finalJ = j;

                // 군주 이름에 따라 색상을 적용
                if (kingdom[finalI][finalJ] != null && lordColors.containsKey(kingdom[finalI][finalJ])) {
                	// 배경색 설정 (기존 코드)
                	Color backgroundColor = lordColors.get(kingdom[finalI][finalJ]);
                	territoryButton.setBackground(backgroundColor);
                	// 배경색에 따라 텍스트 색상 결정
                	Color textColor = getContrastingTextColor(backgroundColor);
                	territoryButton.setForeground(textColor);  // 텍스트 색상 설정
                } else {
                    territoryButton.setBackground(Color.LIGHT_GRAY);  // 기본 배경색
                }

                territoryButton.addActionListener(e -> {
                    if (kingdom[finalI][finalJ]==kingdom[player[0]][player[1]]) {
                    	JOptionPane.showMessageDialog(null, "우호적인 영토입니다.", "알림", JOptionPane.INFORMATION_MESSAGE);
                    } else if (soldier[player[0]][player[1]] < 1) {
                    	JOptionPane.showMessageDialog(null, "공격할 군사가 없습니다.", "주의", JOptionPane.WARNING_MESSAGE);
                    } else if (!isAdjacent(finalI, finalJ, player[0], player[1])) {
                        JOptionPane.showMessageDialog(null, "인접한 영토만 공격할 수 있습니다.", "경고", JOptionPane.ERROR_MESSAGE);
                    } else if (waitingForAttack && isAdjacent(finalI, finalJ, player[0], player[1])) {
                        Attack(player[0], player[1], finalI, finalJ);
                        drawMap();
                        waitingForAttack = false;  // 공격 후 대기 상태 해제
                        endPlayerTurn();  // 플레이어 턴 종료
                    }
                });

                mapPanel.add(territoryButton);
            }
        }

        mapPanel.revalidate();
        mapPanel.repaint();
    }

    // 군주 생성
    static void NewLord(int i, int j) {
    	String name = "";
		if(i==player[0] && j==player[1]) {
			name = Name;
		}else {
			do {
				for (int k = 0; k < 4; k++) {
					int randomNum = (int)(Math.random() * names.length);
					name += names[randomNum];
				}
			} while (kingdoms.containsKey(name));
		}
		kingdoms.put(name, new int[] {i,j});
		if(kingdom[i][j]!=null) {
			if(!kingdoms.containsKey(kingdom[i][j])) {
				log(kingdom[i][j]+"(이)가 몰락하여 "+name+"(이)가 독립하였습니다!");
			}else {
				log(kingdom[i][j]+"(이)가 약해진 틈을 타 "+name+"(이)가 반기를 들었습니다!");
			}
			title[i][j] = 0;
		}
		kingdom[i][j] = name;

        // 군주에게 고유 색상 할당
        if (!lordColors.containsKey(name)) {
            lordColors.put(name, getRandomColor());
        }

    }

  //공격 메서드(a->b)
  	static void Attack(int ax, int ay, int bx, int by) {
  		//전투는 비율로 시행 - ex) 4와 6이 싸우면 4가 이길 확률 4/(4+6) = 40%
  		int battle = (int)(Math.random() * (soldier[ax][ay]+soldier[bx][by]))+1;
  		if(battle<=soldier[ax][ay]) {
  			//승리
  			log(kingdom[ax][ay]+"("+ax+","+ay+")"+soldier[ax][ay]+"가 "+kingdom[bx][by]+"("+bx+","+by+")"+soldier[bx][by]+"를 공격합니다. 결과: 승리");		
  			if(title[bx][by]==0) {
  				//패배국이 군주인 경우
  				title[bx][by]=1;
  				kingdoms.remove(kingdom[bx][by]);
  			}
  			kingdom[bx][by] = kingdom[ax][ay];
  			//군주의 병력 일부를 주둔 시킴 - 신하가 빠르게 영토정복하면 군주의 군사를 소모시켜 반란 유도, 
  			int X = kingdoms.get(kingdom[ax][ay])[0];
  			int Y = kingdoms.get(kingdom[ax][ay])[1];
  			soldier[bx][by] = (int)(soldier[X][Y]/N);
  			soldier[X][Y] -= (int)(soldier[X][Y]/N);
  		}else {
  			//패배
  			log(kingdom[ax][ay]+"("+ax+","+ay+")"+soldier[ax][ay]+"가 "+kingdom[bx][by]+"("+bx+","+by+")"+soldier[bx][by]+"를 공격합니다. 결과: 패배");
  			soldier[ax][ay] = 0; //패배시 군대 손실
  		}
  	}

  	//징병 메서드
  	static void recruit(int ax, int ay) {
  		//접경지역에 따라 차등적인 징병량 구조(3,5,8)	
  		int recruit = fertile[ax][ay];
  		int tax = (int) (soldier[ax][ay]/N);
  		if(title[ax][ay]!=0) {
  			//신하일 때 주군에게 세금 납부	
  			log(kingdom[ax][ay]+"의 "+titles[title[ax][ay]]+"는 징병합니다. "+soldier[ax][ay]+"+"+recruit+"-"+tax+"(세금)");
  			recruit-=tax;
  			int bx = kingdoms.get(kingdom[ax][ay])[0];
  			int by = kingdoms.get(kingdom[ax][ay])[1];
  			soldier[bx][by]+=tax;
  		}else {
  			log(kingdom[ax][ay]+"의 "+titles[title[ax][ay]]+"는 징병합니다. "+soldier[ax][ay]+"+"+recruit);
  		}
  		soldier[ax][ay]+=recruit;
  		
  	}

    // 인접한 영토인지 확인
    static boolean isAdjacent(int x1, int y1, int x2, int y2) {
        return Math.abs(x1 - x2) <= 1 && Math.abs(y1 - y2) <= 1 && !(x1 == x2 && y1 == y2);
    }

    // 플레이어 턴 종료
    public static void endPlayerTurn() {
        playerTurn = false;
        gameTimer.start();  // 플레이어 턴이 끝나면 타이머 재개
    }

    // 랜덤 색상을 생성하는 메서드
    static Color getRandomColor() {
        Random rand = new Random();
        return new Color(rand.nextInt(256), rand.nextInt(256), rand.nextInt(256));
    }

    // 로그 출력 메서드
    static void log(String message) {
        logArea.append(message + "\n");
        logArea.setCaretPosition(logArea.getDocument().getLength());  // 자동 스크롤
    }

    public static void main(String[] args) {
        new RTS5();  // 게임 시작
    }
}
