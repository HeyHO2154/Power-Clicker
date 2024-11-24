package Main.Game;
import java.util.*;

public class Game {

    // 기본 변수
    private int N = 8;
    private int player = -1;
    private int[] personal = new int[N];  // 명예로움, 순수함, 이기적인, 사악한 - 1,0,-1,-2
    private int[] Job = {-1, -1, 0, 0, 0, 0, 1, 2};  // 마피아, 시민, 경찰, 의사 - -1,0,1,2
    private int[] Job_claim = {99, 99, 99, 99, 99, 99, 99, 99};  // 본인 주장 직업(초기 99)

    // 인게임 변수
    private Map<Integer, List<Integer>> Alive = new HashMap<>();  // 시민팀, 마피아팀 - 1,-1
    private Map<Integer, List<Integer>> Enemy = new HashMap<>();  // 적대 인물 리스트(주관적)
    private int[] pick = new int[N];  // 직업으로 선택한 사람(거짓 포함)
    private int[] pick_fake = new int[N];  // 마피아의 가짜 선택
    private int[] suspect_num = new int[N];  // 공론화된 숫자
    private int[] vote = new int[N];  // 투표

    // 시스템 변수
    private int kill;  // 마피아가 죽일 타겟
    private int live;  // 의사가 살릴 타겟
    private boolean[] find = new boolean[N];  // 경찰이 보유중인 조사 리스트
    private boolean[] find_fake = new boolean[N];  // 경찰행세 마피아의 가짜 결과

	// 생성자
    public Game() {
    	// 게임 데이터 초기화 메서드 호출
        initializeGame();
    }
    
    // 게임 시작 시 데이터를 초기화하는 메서드
    public void initializeGame() {
        player = (int) (Math.random()*N);
        for (int i = 0; i < N; i++) {
            personal[i] = (int) (Math.random()*4)-2;
            int job = Job[i];
            int shuffle = (int) (Math.random()*Job.length);
            if(shuffle > i) {
                Job[i] = Job[shuffle];
                Job[shuffle] = job;
            }
            if (Job[i] == -1) {
                Alive.putIfAbsent(-1, new ArrayList<>());
                Alive.get(-1).add(i);
            } else {
                Alive.putIfAbsent(1, new ArrayList<>());
                Alive.get(1).add(i);
            }
            Enemy.putIfAbsent(i, new ArrayList<>());
        }
    }
    
    public int getN() {
		return N;
	}

	public void setN(int n) {
		N = n;
	}

	public int getPlayer() {
		return player;
	}

	public void setPlayer(int player) {
		this.player = player;
	}

	public int[] getPersonal() {
		return personal;
	}

	public void setPersonal(int[] personal) {
		this.personal = personal;
	}

	public int[] getJob() {
		return Job;
	}

	public void setJob(int[] job) {
		Job = job;
	}

	public int[] getJob_claim() {
		return Job_claim;
	}

	public void setJob_claim(int[] job_claim) {
		Job_claim = job_claim;
	}

	public Map<Integer, List<Integer>> getAlive() {
		return Alive;
	}

	public void setAlive(Map<Integer, List<Integer>> alive) {
		Alive = alive;
	}

	public Map<Integer, List<Integer>> getEnemy() {
		return Enemy;
	}

	public void setEnemy(Map<Integer, List<Integer>> enemy) {
		Enemy = enemy;
	}

	public int[] getPick() {
		return pick;
	}

	public void setPick(int[] pick) {
		this.pick = pick;
	}

	public int[] getPick_fake() {
		return pick_fake;
	}

	public void setPick_fake(int[] pick_fake) {
		this.pick_fake = pick_fake;
	}

	public int[] getSuspect_num() {
		return suspect_num;
	}

	public void setSuspect_num(int[] suspect_num) {
		this.suspect_num = suspect_num;
	}

	public int[] getVote() {
		return vote;
	}

	public void setVote(int[] vote) {
		this.vote = vote;
	}

	public int getKill() {
		return kill;
	}

	public void setKill(int kill) {
		this.kill = kill;
	}

	public int getLive() {
		return live;
	}

	public void setLive(int live) {
		this.live = live;
	}

	public boolean[] getFind() {
		return find;
	}

	public void setFind(boolean[] find) {
		this.find = find;
	}

	public boolean[] getFind_fake() {
		return find_fake;
	}

	public void setFind_fake(boolean[] find_fake) {
		this.find_fake = find_fake;
	}



    // Getters and Setters (필요한 변수에 대해)

}
